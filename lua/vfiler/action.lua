local core = require('vfiler/libs/core')
local cmdline = require('vfiler/libs/cmdline')
local sort = require('vfiler/sort')
local vim = require('vfiler/libs/vim')

local Bookmark = require('vfiler/extensions/bookmark')
local Clipboard = require('vfiler/clipboard')
local Menu = require('vfiler/extensions/menu')
local Preview = require('vfiler/preview')
local Rename = require('vfiler/extensions/rename')
local VFiler = require('vfiler/vfiler')

local M = {}

local function create_files(dest, contents, create)
  local created = {}
  for _, name in ipairs(contents) do
    local filepath = core.path.join(dest.path, name)
    local new = create(dest, name, filepath)
    if new then
      table.insert(created, new)
    elseif new == nil then
      core.message.error('Failed to create a "%s" file', name)
    end
  end

  if #created == 0 then
    return nil
  end

  if #created == 1 then
    core.message.info('Created - "%s" file', created[1].name)
  else
    core.message.info('Created - %d files', #created)
  end
  return created
end

local function get_mount_path()
  return core.is_mac and '/Volumes' or '/mnt'
end

local function detect_drives()
  local drives = {}
  if core.is_windows then
    for byte = ('A'):byte(), ('Z'):byte() do
      local drive = string.char(byte) .. ':/'
      if core.path.isdirectory(drive) then
        table.insert(drives, drive)
      end
    end
  else
    local mount = core.path.join(get_mount_path(), '*')
    for _, path in ipairs(vim.fn.glob(mount, 1, 1)) do
      if core.path.isdirectory(path) then
        table.insert(drives, vim.fn.fnamemodify(path, ':t'))
      end
    end
    table.sort(drives)
  end
  return drives
end

local choose_keys = {
  'a',
  's',
  'd',
  'f',
  'g',
  'h',
  'j',
  'k',
  'l',
  'q',
  'w',
  'e',
  'r',
  't',
  'y',
  'u',
  'i',
  'o',
  'p',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  '0',
}

local function choose_window()
  local winnrs = {}
  for nr = 1, vim.fn.winnr('$') do
    local bufnr = vim.fn.winbufnr(nr)
    if bufnr > 0 and vim.fn.getbufvar(bufnr, 'vfiler') ~= 'vfiler' then
      table.insert(winnrs, nr)
    end
  end
  if #winnrs == 0 then
    return -1
  elseif #winnrs == 1 then
    return winnrs[1]
  end

  -- Map window keys, and save statuslines
  local keys = {}
  local winkeys = {}
  local prev_statuslines = {}
  for _, winnr in ipairs(winnrs) do
    local key = choose_keys[winnr]
    table.insert(keys, key)
    winkeys[key] = winnr
    prev_statuslines[winnr] = vim.get_win_option(winnr, 'statusline')
  end

  -- Save status
  local laststatus = vim.get_global_option('laststatus')
  local save_winnr = vim.fn.winnr()

  -- Choose window
  local statusline = require('vfiler/statusline')
  vim.set_global_option('laststatus', 2)
  for key, nr in pairs(winkeys) do
    vim.set_win_option(
      nr,
      'statusline',
      statusline.choose_window_key(vim.fn.winwidth(nr), key)
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
  vim.set_global_option('laststatus', laststatus)
  for nr, prev_statusline in pairs(prev_statuslines) do
    vim.set_win_option(nr, 'statusline', prev_statusline)
    vim.command('redraw')
  end
  core.window.move(save_winnr)

  return key == '<ESC>' and nil or winkeys[key]
end

local function rename_files(vfiler, context, view, targets)
  local rename = Rename.new(vfiler, {
    initial_items = targets,
    on_execute = function(filer, c, v, items, renames)
      local renamed = {}
      local num_renamed = 0
      for i = 1, #items do
        local item = items[i]
        local rename = renames[i]

        if item:rename(rename) then
          table.insert(renamed, item)
          num_renamed = num_renamed + 1
          item.selected = false
        end
      end

      if #renamed > 0 then
        core.message.info('Renamed - %d files', #renamed)
        M.reload(filer, c, v)
        v:move_cursor(renamed[1].path)
      end
    end,
  })
  M.start_extension(vfiler, context, view, rename)
end

local function rename_one_file(vfiler, context, view, target)
  local name = target.name
  local rename = cmdline.input('New file name - ' .. name, name, 'file')
  if #rename == 0 then
    return -- Canceled
  end

  -- Check overwrite
  local filepath = core.path.join(target.parent.path, rename)
  if core.path.exists(filepath) == 1 then
    if cmdline.util.confirm_overwrite(rename) ~= cmdline.choice.YES then
      return
    end
  end

  if not target:rename(rename) then
    return
  end

  core.message.info('Renamed - "%s" -> "%s"', name, rename)
  view:draw(context)
end

local function close_preview(vfiler, context, view)
  local preview = context.in_preview.preview
  if not (preview and preview.opened) then
    return false
  end
  preview:close()
  if not preview.isfloating then
    view:redraw()
  end
  return true
end

local function open_preview(vfiler, context, view)
  local preview = context.in_preview.preview
  if not preview then
    return
  end

  preview.line = vim.fn.line('.')
  local item = view:get_item(preview.line)
  if item.isdirectory then
    preview:close()
  else
    preview:open(item.path)
  end
  if not preview.isfloating then
    view:redraw()
  end
end

------------------------------------------------------------------------------
-- Interfaces
------------------------------------------------------------------------------

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

function M.open_file(vfiler, context, view, path, open)
  local isdirectory = core.path.isdirectory(path)
  if open == 'edit' then
    if isdirectory then
      M.cd(vfiler, context, view, path)
      return
    elseif context.options.keep then
      -- change the action if the "keep" option is enabled
      open = 'choose'
    end
  end

  if open == 'choose' then
    local winnr = choose_window()
    if not winnr then
      return
    elseif winnr < 0 then
      core.window.open('right')
    else
      core.window.move(winnr)
    end
  elseif open ~= 'edit' then
    core.window.open(open)
  end

  if isdirectory then
    local newfiler = VFiler.find_hidden(context.options.name)
    if newfiler then
      newfiler:open()
      newfiler:reset(context)
    else
      local newcontext = context:duplicate()
      newfiler = VFiler.new(newcontext)
    end
    newfiler:start(path)
  else
    core.window.open('edit', path)
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

------------------------------------------------------------------------------
-- actions
------------------------------------------------------------------------------

function M.clear_selected_all(vfiler, context, view)
  for _, item in ipairs(view:selected_items()) do
    item.selected = false
  end
  view:redraw()
end

function M.close_preview(vfiler, context, view)
  if not close_preview(vfiler, context, view) then
    return
  end
  local in_preview = context.in_preview
  if in_preview.once then
    in_preview.preview = nil
  end
end

function M.close_tree(vfiler, context, view)
  local item = view:get_current()
  local target = (item.isdirectory and item.opened) and item or item.parent

  target:close()
  view:draw(context)
  view:move_cursor(target.path)
end

function M.close_tree_or_cd(vfiler, context, view)
  local item = view:get_current()
  local level = item and item.level or 0
  if level == 0 or (level <= 1 and not item.opened) then
    local path = context.root.path
    M.cd(vfiler, context, view, context:parent_path(), function()
      view:move_cursor(path)
    end)
  else
    M.close_tree(vfiler, context, view)
  end
end

function M.change_sort(vfiler, context, view)
  local menu = Menu.new(vfiler, 'Select Sort', {
    initial_items = sort.types(),
    default = context.options.sort,

    on_selected = function(filer, c, v, sort_type)
      if c.sort == sort_type then
        return
      end

      local item = v:get_current()
      c.sort = sort_type
      v:draw(c)
      v:move_cursor(item.path)
    end,
  })
  M.start_extension(vfiler, context, view, menu)
end

function M.change_to_parent(vfiler, context, view)
  M.cd(vfiler, context, view, context:parent_path())
end

function M.copy(vfiler, context, view)
  local selected = view:selected_items()
  if #selected == 0 then
    return
  end

  context.clipboard = Clipboard.copy(selected)
  if #selected == 1 then
    core.message.info('Copy to the clipboard - %s', selected[1].name)
  else
    core.message.info('Copy to the clipboard - %d files', #selected)
  end

  -- clear selected mark
  for _, item in ipairs(selected) do
    item.selected = false
  end
  view:redraw()
end

function M.copy_to_filer(vfiler, context, view)
  local selected = view:selected_items()
  if #selected == 0 then
    return
  end
  local linked = context.linked
  if not (linked and linked:displayed()) then
    -- Copy to clipboard
    M.copy(vfiler, context, view)
    return
  end

  -- Copy to linked filer
  local cb = Clipboard.copy(selected)
  cb:paste(linked:get_root_item())
  linked:open()
  linked:draw()

  -- Return to current
  vfiler:open()

  -- clear selected mark
  for _, item in ipairs(selected) do
    item.selected = false
  end
  view:redraw()
end

function M.delete(vfiler, context, view)
  local selected = view:selected_items()
  if #selected == 0 then
    return
  end

  local prompt = 'Are you sure you want to delete? - '
  if #selected > 1 then
    prompt = prompt .. #selected .. ' files'
  else
    prompt = prompt .. selected[1].name
  end

  local choices = { cmdline.choice.YES, cmdline.choice.NO }
  if cmdline.confirm(prompt, choices, 2) ~= cmdline.choice.YES then
    return
  end

  -- delete files
  local deleted = {}
  for _, item in ipairs(selected) do
    if item:delete() then
      table.insert(deleted, item)
    end
  end

  if #deleted == 0 then
    return
  elseif #deleted == 1 then
    core.message.info('Deleted - %s', deleted[1].name)
  else
    core.message.info('Deleted - %d files', #deleted)
  end
  view:draw(context)
end

function M.execute_file(vfiler, context, view)
  local item = view:get_current()
  if item then
    core.file.execute(item.path)
  else
    core.message.error('File does not exist.')
  end
end

function M.jump_to_directory(vfiler, context, view)
  local dirpath = cmdline.input('Jump to?', '', 'dir')
  if #dirpath == 0 then
    return
  end
  dirpath = core.path.normalize(dirpath)
  if not core.path.isdirectory(dirpath) then
    core.message.error('Not exists the "%s" path.', dirpath)
    return
  end
  M.cd(vfiler, context, view, dirpath)
end

function M.jump_to_home(vfiler, context, view)
  local dirpath = vim.fn.expand('~')
  M.cd(vfiler, context, view, dirpath)
end

function M.jump_to_root(vfiler, context, view)
  local dirpath = core.path.root(context.root.path)
  M.cd(vfiler, context, view, dirpath)
end

function M.latest_update(vfiler, context, view)
  local root = context.root
  if vim.fn.getftime(root.path) > root.time then
    M.reload(vfiler, context, view)
    return
  end

  for item in view:walk_items() do
    if item.isdirectory then
      if vim.fn.getftime(item.path) > item.time then
        M.reload(vfiler, context, view)
        return
      end
    end
  end
end

function M.add_bookmark(vfiler, context, view)
  local item = view:get_current()
  Bookmark.add(item)
end

function M.list_bookmark(vfiler, context, view)
  local bookmark = Bookmark.new(vfiler, {
    on_selected = function(filer, c, v, path, open_type)
      M.open_file(filer, c, v, path, open_type)
    end,
  })
  M.start_extension(vfiler, context, view, bookmark)
end

function M.loop_cursor_down(vfiler, context, view)
  local lnum = vim.fn.line('.') + 1
  local num_end = view:num_lines()
  if lnum > num_end then
    core.cursor.move(view:top_lnum())
    -- Correspondence to show the header line
    -- when moving to the beginning of the line.
    vim.command('normal zb')
  else
    core.cursor.move(lnum)
  end
end

function M.loop_cursor_up(vfiler, context, view)
  local lnum = vim.fn.line('.') - 1
  if lnum < view:top_lnum() then
    lnum = view:num_lines()
  end
  core.cursor.move(lnum)
end

function M.move(vfiler, context, view)
  local selected = view:selected_items()
  if #selected == 0 then
    return
  end

  context.clipboard = Clipboard.move(selected)
  if #selected == 1 then
    core.message.info('Move to the clipboard - %s', selected[1].name)
  else
    core.message.info('Move to the clipboard - %d files', #selected)
  end

  -- clear selected mark
  for _, item in ipairs(selected) do
    item.selected = false
  end
  view:redraw()
end

function M.move_cursor_bottom(vfiler, context, view)
  core.cursor.move(view:num_lines())
end

function M.move_cursor_down(vfiler, context, view)
  local lnum = vim.fn.line('.') + 1
  core.cursor.move(lnum)
end

function M.move_cursor_top(vfiler, context, view)
  core.cursor.move(view:top_lnum())
  -- Correspondence to show the header line
  -- when moving to the beginning of the line.
  vim.command('normal zb')
end

function M.move_cursor_up(vfiler, context, view)
  local lnum = math.max(view:top_lnum(), vim.fn.line('.') - 1)
  core.cursor.move(lnum)
end

function M.move_to_filer(vfiler, context, view)
  local selected = view:selected_items()
  if #selected == 0 then
    return
  end
  local linked = context.linked
  if not (linked and linked:displayed()) then
    -- Move to clipboard
    M.move(vfiler, context, view)
    return
  end

  -- Move to linked filer
  local cb = Clipboard.move(selected)
  cb:paste(linked:get_root_item())
  linked:open()
  linked:draw()

  vfiler:open()
  view:draw(context)
end

function M.new_directory(vfiler, context, view)
  local item = view:get_current()
  local dir = (item.isdirectory and item.opened) and item or item.parent

  local function create_directory(dest, name, filepath)
    if core.path.isdirectory(filepath) then
      if cmdline.util.confirm_overwrite(name) ~= cmdline.choice.YES then
        return false
      end
    elseif core.is_windows and core.path.filereadable(filepath) then
      core.message.warning(
        'Not created. "%s" file with the same name already exists.',
        name
      )
      return false
    end
    return dest:create_directory(name)
  end

  cmdline.input_multiple('New directory names?', function(contents)
    local created = create_files(dir, contents, create_directory)
    if created then
      view:draw(context)
      -- move the cursor to the created item path
      view:move_cursor(created[1].path)
    end
  end)
end

function M.new_file(vfiler, context, view)
  local item = view:get_current()
  local dir = (item.isdirectory and item.opened) and item or item.parent

  local function create_file(dest, name, filepath)
    if core.path.filereadable(filepath) then
      if cmdline.util.confirm_overwrite(name) ~= cmdline.choice.YES then
        return false
      end
    elseif core.is_windows and core.path.isdirectory(filepath) then
      core.message.warning(
        'Not created. "%s" directory with the same name already exists.',
        name
      )
      return false
    end
    return dest:create_file(name)
  end

  cmdline.input_multiple('New file names?', function(contents)
    local created = create_files(dir, contents, create_file)
    if created then
      view:draw(context)
      -- move the cursor to the created item path
      view:move_cursor(created[1].path)
    end
  end)
end

function M.open(vfiler, context, view)
  local path = view:get_current().path
  M.open_file(vfiler, context, view, path, 'edit')
end

function M.open_by_choose(vfiler, context, view)
  local path = view:get_current().path
  M.open_file(vfiler, context, view, path, 'choose')
end

function M.open_by_choose_or_cd(vfiler, context, view)
  local item = view:get_current()
  if item.isdirectory then
    M.cd(vfiler, context, view, item.path)
  else
    M.open_file(vfiler, context, view, item.path, 'choose')
  end
end

function M.open_by_split(vfiler, context, view)
  local path = view:get_current().path
  M.open_file(vfiler, context, view, path, 'bottom')
end

function M.open_by_tabpage(vfiler, context, view)
  local path = view:get_current().path
  M.open_file(vfiler, context, view, path, 'tab')
end

function M.open_by_vsplit(vfiler, context, view)
  local path = view:get_current().path
  M.open_file(vfiler, context, view, path, 'right')
end

function M.open_tree(vfiler, context, view)
  local lnum = vim.fn.line('.')
  local item = view:get_item(lnum)
  if not item.isdirectory or item.opened then
    return
  end
  item:open()
  view:draw(context)
  core.cursor.move(lnum + 1)
end

function M.open_tree_recursive(vfiler, context, view)
  local lnum = vim.fn.line('.')
  local item = view:get_item(lnum)
  if not item.isdirectory or item.opened then
    return
  end
  item:open(true)
  view:draw(context)
  core.cursor.move(lnum + 1)
end

function M.paste(vfiler, context, view)
  local cb = context.clipboard
  if not cb then
    core.message.warning('No clipboard')
    return
  end

  local item = view:get_current()
  local dest = (item.isdirectory and item.opened) and item or item.parent
  if cb:paste(dest) and cb.keep then
    context.clipboard = nil
  end
  view:draw(context)
end

function M.preview_cursor_moved(vfiler, context, view)
  local in_preview = context.in_preview
  local preview = in_preview.preview
  if not preview then
    return
  end

  local line = vim.fn.line('.')
  if preview.line ~= line then
    if in_preview.once then
      M.close_preview(vfiler, context, view)
    else
      open_preview(vfiler, context, view)
    end
  end
  preview.line = line
end

function M.toggle_auto_preview(vfiler, context, view)
  local in_preview = context.in_preview
  local preview = in_preview.preview
  if preview and not in_preview.once then
    preview:close()
    view:redraw()
    in_preview.preview = nil
    return
  end

  if not preview then
    in_preview.preview = Preview.new(context.options.preview)
  end
  in_preview.once = false
  open_preview(vfiler, context, view)
end

function M.toggle_preview(vfiler, context, view)
  local in_preview = context.in_preview
  if close_preview(vfiler, context, view) then
    if in_preview.once then
      in_preview.preview = nil
    end
    return
  end
  if not in_preview.preview then
    in_preview.preview = Preview.new(context.options.preview)
    in_preview.once = true
  end
  open_preview(vfiler, context, view)
end

function M.quit(vfiler, context, view)
  vfiler:quit()
end

function M.redraw(vfiler, context, view)
  context:reload_gitstatus(function()
    view:draw(context)
  end)
  open_preview(vfiler, context, view)
end

function M.reload(vfiler, context, view)
  context:save(view:get_current().path)
  context:switch(context.root.path, function(ctx)
    view:draw(ctx)
  end)
  open_preview(vfiler, context, view)
end

function M.rename(vfiler, context, view)
  local selected = view:selected_items()
  if #selected == 1 then
    rename_one_file(vfiler, context, view, selected[1])
  elseif #selected > 1 then
    rename_files(vfiler, context, view, selected)
  end
end

function M.switch_to_drive(vfiler, context, view)
  local drives = detect_drives()
  if #drives == 0 then
    return
  end

  local root = core.path.root(context.root.path)
  local menu = Menu.new(vfiler, 'Select Drive', {
    initial_items = drives,
    default = root,

    on_selected = function(filer, ctx, v, drive)
      if core.is_windows then
        if root == drive then
          return
        end
      else
        drive = core.path.join(get_mount_path(), drive)
      end

      local path = v:get_current().path
      ctx:save(path)
      ctx:switch_drive(drive, function(c, p)
        v:draw(c)
        v:move_cursor(p)
      end)
    end,
  })
  M.start_extension(vfiler, context, view, menu)
end

function M.switch_to_filer(vfiler, context, view)
  -- close preview window
  M.close_preview(vfiler, context, view)

  local linked = context.linked
  -- already linked
  if linked then
    linked:open('right')
    linked:do_action(open_preview)
    return
  end

  -- create link to filer
  local lnum = vim.fn.line('.')
  local newfiler = VFiler.find_hidden(context.options.name)
  if newfiler then
    newfiler:open('right')
    newfiler:reset(context)
  else
    core.window.open('right')
    newfiler = vfiler:duplicate()
  end
  newfiler:link(vfiler)
  newfiler:start(context.root.path)
  core.cursor.move(lnum)

  -- redraw current
  vfiler:open()
  view:draw(context)

  newfiler:open() -- return other filer
  newfiler:do_action(open_preview)
end

function M.sync_with_current_filer(vfiler, context, view)
  local linked = context.linked
  if not (linked and linked:displayed()) then
    return
  end

  linked:open()
  linked:sync(context, function()
    linked:draw()
    vfiler:open() -- return current window
  end)
end

function M.toggle_show_hidden(vfiler, context, view)
  local options = context.options
  options.show_hidden_files = not options.show_hidden_files
  view:draw(context)
end

function M.toggle_select(vfiler, context, view)
  local lnum = vim.fn.line('.')
  local item = view:get_item(lnum)
  item.selected = not item.selected
  view:redraw_line(lnum)
end

function M.toggle_select_all(vfiler, context, view)
  for item in view:walk_items() do
    item.selected = not item.selected
  end
  view:redraw()
end

function M.toggle_select_down(vfiler, context, view)
  M.toggle_select(vfiler, context, view)
  M.move_cursor_down(vfiler, context, view)
end

function M.toggle_select_up(vfiler, context, view)
  M.toggle_select(vfiler, context, view)
  M.move_cursor_up(vfiler, context, view)
end

function M.toggle_sort(vfiler, context, view)
  local sort_type = context.sort
  local initial = sort_type:sub(1, 1)
  local backward = sort_type:sub(2)

  if initial:find('^[A-Z]') then
    initial = initial:lower()
  else
    initial = initial:upper()
  end
  context.sort = initial .. backward
  view:draw(context)
end

function M.yank_name(vfiler, context, view)
  local selected = view:selected_items()
  local names = {}
  for _, item in ipairs(selected) do
    table.insert(names, item.name)
  end
  if #names == 1 then
    Clipboard.yank(names[1])
    core.message.info('Yanked name - "%s"', names[1])
  elseif #names > 1 then
    local content = table.concat(names, '\n')
    Clipboard.yank(content)
    core.message.info('Yanked %d names', #names)
  end

  -- clear selected mark
  for _, item in ipairs(selected) do
    item.selected = false
  end
  view:redraw()
end

function M.yank_path(vfiler, context, view)
  local selected = view:selected_items()
  local paths = {}
  for _, item in ipairs(selected) do
    table.insert(paths, item.path)
  end
  if #paths == 1 then
    Clipboard.yank(paths[1])
    core.message.info('Yanked path - "%s"', paths[1])
  elseif #paths > 1 then
    local content = table.concat(paths, '\n')
    Clipboard.yank(content)
    core.message.info('Yanked %d paths', #paths)
  end

  -- clear selected mark
  for _, item in ipairs(selected) do
    item.selected = false
  end
  view:redraw()
end

return M
