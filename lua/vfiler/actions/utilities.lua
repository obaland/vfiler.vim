local cmdline = require('vfiler/libs/cmdline')
local config = require('vfiler/actions/config')
local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local M = {}

-- stylua: ignore
local choose_keys = {
  'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'q',
  'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '1',
  '2', '3', '4', '5', '6', '7', '8', '9', '0',
}

local function get_key_status_string(winwidth, key)
  local caption_width = winwidth / 4
  local padding = (' '):rep(math.ceil(caption_width / 2))
  local margin = (' '):rep(math.ceil((winwidth - caption_width) / 2))
  local status = {
    '%#vfilerStatusLine#',
    margin,
    '%#vfilerStatusLineSection#',
    padding,
    key,
    padding,
    '%#vfilerStatusLine#',
  }
  return table.concat(status, '')
end

local function choose_window(winid)
  local Buffer = require('vfiler/buffer')

  local winids = {}
  for winnr = 1, vim.fn.winnr('$') do
    local bufnr = vim.fn.winbufnr(winnr)
    if
      vim.fn.bufwinnr(bufnr) >= 1
      and (not Buffer.is_vfiler_buffer(bufnr))
    then
      table.insert(winids, vim.fn.win_getid(winnr))
    end
  end
  local hook = config.configs.hook.filter_choose_window
  if hook then
    winids = hook(winids)
  end
  if not winids or #winids == 0 then
    return -1
  elseif #winids == 1 then
    return winids[1]
  end

  -- Map window keys, and save statuslines
  local keys = {}
  local winkeys = {}
  local prev_statuslines = {}
  for _, id in ipairs(winids) do
    local winnr = vim.fn.win_id2win(id)
    local key = choose_keys[winnr]
    table.insert(keys, key)
    winkeys[key] = id
    prev_statuslines[id] = vim.get_win_option(id, 'statusline')
  end

  -- Save status
  local laststatus = vim.get_option('laststatus')

  -- Choose window
  vim.set_option('laststatus', 2)
  for key, id in pairs(winkeys) do
    vim.set_win_option(
      id,
      'statusline',
      get_key_status_string(vim.fn.winwidth(id), key)
    )
    vim.command('redraw')
  end

  local key
  local prompt = ('choose (%s) ?'):format(table.concat(keys, '/'))
  repeat
    key = cmdline.getchar(prompt)
    cmdline.clear_prompt()
    if key == '<ESC>' then
      break
    end
  until winkeys[key]

  -- Restore
  vim.set_option('laststatus', laststatus)
  for id, prev_statusline in pairs(prev_statuslines) do
    vim.set_win_option(id, 'statusline', prev_statusline)
    vim.command('redraw')
  end
  core.window.move(winid)

  return key == '<ESC>' and nil or winkeys[key]
end

local function open_file(vfiler, context, view, path, layout)
  if view:type() == 'floating' then
    vfiler:quit()
  end
  if layout ~= 'none' then
    core.window.open(layout)
  end
  if core.path.is_directory(path) then
    local newfiler = vfiler:copy()
    newfiler:set_size(0, 0)
    newfiler:open()
    newfiler:start(path)
  else
    local Buffer = require('vfiler/buffer')
    local result = core.window.open('none', path)
    if not result then
      -- NOTE: correspondence of "ATTENTION E325"
      local bufname = vim.fn.bufname()
      if Buffer.is_vfiler_buffer(vim.fn.bufnr()) or #bufname == 0 then
        vim.command('quit!')
      end
    end
  end

  local dest_winid = vim.fn.win_getid()
  local winid = view:winid()
  if winid > 0 and dest_winid ~= winid then
    view:redraw()
  end
end

local function choose_file(vfiler, context, view, path)
  local winid = choose_window(view:winid())
  if not winid then
    return
  elseif winid < 0 then
    core.window.open('right', '')
  else
    -- for example, dare to raise the autocmd event and close
    -- the preview window.
    core.window.move(winid, true)
  end
  open_file(vfiler, context, view, path, 'none')
end

local function edit_file(vfiler, context, view, path)
  if core.path.is_directory(path) then
    M.cd(vfiler, context, view, path)
  elseif context.options.keep then
    -- change the action if the "keep" option is enabled
    choose_file(vfiler, context, view, path)
  else
    core.window.open('none', path)
  end
end

function M.cd(vfiler, context, view, dirpath)
  if context.root and context.root.path == dirpath then
    -- Same directory path
    return
  end

  local current = view:get_item()
  if current then
    context:save(current.path)
  end
  local path = context:switch(dirpath)
  view:draw(context)
  view:move_cursor(path)
  view:reload_git_async(context.root.path, function(v)
    v:redraw()
  end)
end

function M.close_preview(vfiler, context, view)
  local in_preview = context.in_preview
  local preview = in_preview.preview
  if not (preview and preview.opened) then
    return false
  end
  preview:close()
  if in_preview.once then
    in_preview.preview = nil
  end
  return true
end

function M.open_preview(vfiler, context, view)
  local preview = context.in_preview.preview
  if not preview then
    return false
  end

  preview.line = vim.fn.line('.')
  local item = view:get_item(preview.line)
  if item.type == 'directory' then
    preview:close()
  else
    local hook = config.configs.hook.read_preview_file
    if type(hook) ~= 'function' then
      hook = function(path, read_func)
        return read_func(path)
      end
    end
    preview:open(item.path, hook)
  end
  return true
end

function M.open_file(vfiler, context, view, path, layout)
  -- Supports Windows shortcut file
  if core.is_windows and core.path.extension(path) == 'lnk' then
    path = vim.fn.resolve(path)
  end

  layout = layout or 'none'
  if layout == 'none' then
    edit_file(vfiler, context, view, path)
  elseif layout == 'choose' then
    choose_file(vfiler, context, view, path)
  else
    open_file(vfiler, context, view, path, layout)
  end
  context:perform_auto_cd()
end

function M.open_tree(_, context, view, recursive)
  local lnum = vim.fn.line('.')
  local item = view:get_item(lnum)
  if item.type ~= 'directory' or item.opened then
    return
  end
  item:open(recursive)
  view:draw(context)
  lnum = lnum + 1
  core.cursor.move(lnum)
  context:save(view:get_item(lnum).path)
  view:reload_git_async(item.path, function(v)
    v:redraw()
  end)
end

function M.start_extension(vfiler, context, view, extension)
  if context.extension then
    return
  end
  -- close the preview window before starting
  M.close_preview(vfiler, context, view)
  extension:start()
end

return M
