local cmdline = require('vfiler/libs/cmdline')
local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local Buffer = require('vfiler/buffer')

local M = {}

-- stylua: ignore
local choose_keys = {
  'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'q',
  'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '1',
  '2', '3', '4', '5', '6', '7', '8', '9', '0',
}

local function choose_window(winid)
  local winids = {}
  for winnr = 1, vim.fn.winnr('$') do
    local bufnr = vim.fn.winbufnr(winnr)
    if not Buffer.is_vfiler_buffer(bufnr) then
      table.insert(winids, vim.fn.win_getid(winnr))
    end
  end
  if #winids == 0 then
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
  local status = require('vfiler/status')
  vim.set_option('laststatus', 2)
  for key, id in pairs(winkeys) do
    vim.set_win_option(
      id,
      'statusline',
      status.choose_window_key(vim.fn.winwidth(id), key)
    )
    vim.command('redraw')
  end

  local key
  local prompt = ('choose (%s) ?'):format(table.concat(keys, '/'))
  repeat
    key = cmdline.getchar(prompt)
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
  if layout ~= 'none' then
    core.window.open(layout)
  end
  if core.path.is_directory(path) then
    local newfiler = vfiler:copy()
    newfiler:set_size(0, 0)
    newfiler:open()
    newfiler:start(path)
  else
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
  --if layout ~= 'tab' and dest_winid ~= view:winid() then
  if dest_winid ~= view:winid() then
    vfiler:focus()
    view:redraw()
    core.window.move(dest_winid)
  end
end

local function choose_file(vfiler, context, view, path)
  local winid = choose_window(view:winid())
  if not winid then
    return
  elseif winid < 0 then
    core.window.open('right')
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

function M.cd(vfiler, context, view, dirpath, on_completed)
  if context.root and context.root.path == dirpath then
    -- Same directory path
    return
  end

  local current = view:get_current()
  if current then
    context:save(current.path)
  end
  context:switch(dirpath, function(ctx, path)
    view:draw(ctx)
    view:move_cursor(path)
    if on_completed then
      on_completed()
    end
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
    preview:open(item.path)
  end
  return true
end

function M.open_file(vfiler, context, view, path, layout)
  layout = layout or 'none'
  if layout == 'none' then
    edit_file(vfiler, context, view, path)
  elseif layout == 'choose' then
    choose_file(vfiler, context, view, path)
  else
    open_file(vfiler, context, view, path, layout)
  end
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
