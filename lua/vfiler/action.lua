local core = require 'vfiler/core'
local cmdline = require 'vfiler/cmdline'
local sort = require 'vfiler/sort'
local vim = require 'vfiler/vim'

local Clipboard = require 'vfiler/clipboard'
local Menu = require 'vfiler/extensions/menu'
local Rename = require 'vfiler/extensions/rename'
local Directory = require 'vfiler/items/directory'
local File = require 'vfiler/items/file'
local VFiler = require 'vfiler/vfiler'

local M = {}

-- @param lnum number
local function move_cursor(lnum)
  vim.fn.cursor(lnum, 1)
end

local function cd(context, view, dirpath)
  if context.root and context.root.path == dirpath then
    -- Same directory path
    return
  end

  local current = view:get_current()
  if current then
    context:save(current.path)
  end
  local path = context:switch(dirpath, true)
  view:draw(context)

  -- Skip header line
  move_cursor(math.max(view:indexof(path), 2))
end

local function create_files(dest, contents, create)
  local created = {}
  for _, name in ipairs(contents) do
    local filepath = core.path.join(dest.path, name)
    if core.path.isdirectory(filepath) then
      core.message.warning('Skipped, "%s" already exists', name)
    else
      local new = create(dest, filepath)
      if new then
        dest:add(new)
        table.insert(created, name)
      else
        core.message.error('Failed to create a "%s" file', name)
      end
    end
  end

  if #created == 0 then
    return false
  end

  if #created == 1 then
    core.message.info('Created - "%s" file', created[1])
  else
    core.message.info('Created - %d files', #created)
  end
  return true
end

local function detect_drives()
  if not core.is_windows then
    return {}
  end
  local drives = {}
  for byte = ('A'):byte(), ('Z'):byte() do
    local drive = string.char(byte) .. ':/'
    if core.path.isdirectory(drive) then
      table.insert(drives, drive)
    end
  end
  return drives
end

local function open(context, view, direction)
  local item = view:get_current()
  if not item then
    core.message.warning('Item does not exist.')
    return
  end

  if item.isdirectory then
    if direction == 'edit' then
      cd(context, view, item.path)
      return
    end
    local vfiler = VFiler.get_current()
    core.window.open(direction)
    M.start(item.path, vfiler.configs)
    return
  end
  core.window.open(direction, item.path)
end

local function rename_files(context, view, targets)
  if context.extension then
    return
  end

  local ext = Rename.new {
    on_execute = function(items, renames)
      local num_renamed = 0
      local parents = {}
      for i = 1, #items do
        local item = items[i]
        local rename = renames[i]
        local filepath = core.path.join(item.parent.path, rename)

        local result = true
        if core.path.exists(filepath) then
          if cmdline.util.confirm_overwrite(rename) == cmdline.choice.YES then
            result = item:rename(rename)
          end
        else
          result = item:rename(rename)
        end

        if result then
          num_renamed = num_renamed + 1
          parents[item.parent.path] = item.parent
        end
      end

      if num_renamed > 0 then
        core.message.info('Renamed - %d files', num_renamed)
        for _, parent in pairs(parents) do
          parent:sort(context.sort_type, false)
        end
        view:draw(context)
      end
    end,

    on_quit = function()
      context.extension = nil
    end,
  }

  ext:start(targets)
  context.extension = ext
end

local function rename_one_file(context, view, target)
  local name = target.name
  local rename = cmdline.input('New file name - ' .. name, name , 'file')
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
  target.parent:sort(context.sort_type, false)
  view:draw(context)
end

------------------------------------------------------------------------------
-- Interfaces
------------------------------------------------------------------------------
function M.define(name, func)
  M[name] = func
end

function M._do_action(name, ...)
  if not M[name] then
    core.message.error('Action "%s" is not defined.', name)
    return
  end

  local vfiler = VFiler.get(vim.fn.bufnr())
  if not vfiler then
    core.message.error('Buffer does not exist.')
    return
  end
  M[name](vfiler.context, vfiler.view, ...)
end

function M.do_action(bufnr, func)
  local vfiler = VFiler.get(bufnr)
  if not vfiler then
    core.message.error('Buffer does not exist.')
    return
  end
  func(vfiler.context, vfiler.view)
end

function M.start(dirpath, configs)
  local vfiler = VFiler.new(configs)
  cd(vfiler.context, vfiler.view, dirpath)
  move_cursor(2)
end

function M.undefine(name)
  M[name] = nil
end

------------------------------------------------------------------------------
-- actions
------------------------------------------------------------------------------

function M.clear_selected_all(context, view)
  for _, item in ipairs(context.root:walk()) do
    item.selected = false
  end
  view:redraw()
end

function M.close_tree(context, view)
  local item = view:get_current()
  local target = (item.isdirectory and item.opened) and item or item.parent

  target:close()
  view:draw(context)

  -- Skip header line
  move_cursor(math.max(view:indexof(target.path), 2))
end

function M.close_tree_or_cd(context, view)
  local item = view:get_current()
  if item.level <= 1 and not item.opened then
    local path = context.root:parent_path()
    cd(context, view, path)
  else
    M.close_tree(context, view)
  end
end

function M.change_sort(context, view)
  if context.extension then
    return
  end

  local menu = Menu.new {
    name = 'Select Sort',

    on_selected = function(sort_type)
      if context.sort_type ~= sort_type then
        local item = view:get_current()

        context:change_sort(sort_type)
        view:draw(context)

        -- Skip header line
        move_cursor(math.max(view:indexof(item.path), 2))
      end
    end,

    on_quit = function()
      context.extension = nil
    end,
  }

  menu:start(sort.types(), context.sort_type)
  context.extension = menu
end

function M.change_to_parent(context, view)
  cd(context, view, context.root:parent_path())
end

function M.copy(context, view)
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
end

function M.copy_to_filer(context, view)
  local selected = view:selected_items()
  if #selected == 0 then
    return
  end
  local current = VFiler.get(view.bufnr)
  local linked = current.linked
  if not (linked and linked.view:displayed()) then
    -- Copy to clipboard
    M.copy(context, view)
    return
  end

  -- Copy to linked filer
  local cb = Clipboard.copy(selected)
  cb:paste(linked.context.root)
  linked:open()
  M.redraw(linked.context, linked.view)
  current:open() -- Return to current
end

function M.delete(context, view)
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

  local choice = cmdline.confirm(
    prompt,
    {cmdline.choice.YES, cmdline.choice.NO},
    2
    )
  if choice ~= cmdline.choice.YES then
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

function M.execute_file(context, view)
  local item = view:get_current()
  if item then
    core.file.execute(item.path)
  else
    core.message.error('File does not exist.')
  end
end

function M.jump_to_directory(context, view)
  local dirpath = cmdline.input('Jump to?', '', 'dir')
  if #dirpath == 0 then
    return
  end
  dirpath = core.path.normalize(dirpath)
  if not core.path.isdirectory(dirpath) then
    core.message.error('Not exists the "%s" path.', dirpath)
    return
  end
  cd(context, view, dirpath)
  vim.command('echo') -- clear prompt message
end

function M.jump_to_home(context, view)
  local dirpath = vim.fn.expand('~')
  cd(context, view, dirpath)
end

function M.jump_to_root(context, view)
  local dirpath = context.root:root()
  cd(context, view, dirpath)
end

function M.loop_cursor_down(context, view)
  local lnum = vim.fn.line('.') + 1
  local num_end = view:num_lines()
  if lnum > num_end then
    -- the meaning of "2" is to skip the header line
    lnum = 2
  end
  move_cursor(lnum)
end

function M.loop_cursor_up(context, view, loop)
  local lnum = vim.fn.line('.') - 1
  if lnum <= 1 then
    lnum = view:num_lines()
  end
  move_cursor(lnum)
end

function M.move(context, view)
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
end

function M.move_cursor_bottom(context, view)
  move_cursor(view:num_lines())
end

function M.move_cursor_down(context, view)
  local lnum = vim.fn.line('.') + 1
  move_cursor(lnum)
end

function M.move_cursor_top(context, view)
  move_cursor(2)
end

function M.move_cursor_up(context, view)
  -- the meaning of "2" is to skip the header line
  local lnum = math.max(2, vim.fn.line('.') - 1)
  move_cursor(lnum)
end

function M.move_to_filer(context, view)
  local selected = view:selected_items()
  if #selected == 0 then
    return
  end
  local current = VFiler.get(view.bufnr)
  local linked = current.linked
  if not (linked and linked.view:displayed()) then
    -- Move to clipboard
    M.move(context, view)
    return
  end

  -- Move to linked filer
  local cb = Clipboard.move(selected)
  cb:paste(linked.context.root)
  linked:open()
  M.redraw(linked.context, linked.view)
  current:open()
  M.redraw(current.context, current.view)
end

function M.new_directory(context, view)
  local item = view:get_current()
  local dir = (item.isdirectory and item.opened) and item or item.parent

  cmdline.input_multiple('New directory names?',
    function(contents)
      local result = create_files(dir, contents, function(dest, filepath)
        return Directory.create(filepath, dest.sort_type)
      end)
      if result then
        view:draw(context)
      end
    end)
end

function M.new_file(context, view)
  local item = view:get_current()
  local dir = (item.isdirectory and item.opened) and item or item.parent

  cmdline.input_multiple('New file names?',
    function(contents)
      local result = create_files(dir, contents, function(dest, filepath)
        return File.create(filepath)
      end)
      if result then
        view:draw(context)
      end
    end)
end

function M.open(context, view)
  open(context, view, 'edit')
end

function M.open_by_split(context, view)
  open(context, view, 'right')
end

function M.open_by_tabpage(context, view)
  open(context, view, 'tab')
end

function M.open_by_vsplit(context, view)
  open(context, view, 'bottom')
end

function M.open_tree(context, view)
  local lnum = vim.fn.line('.')
  local item = view:get_item(lnum)
  if not item.isdirectory or item.opened then
    return
  end
  item:open()
  view:draw(context)
  move_cursor(lnum + 1)
end

function M.paste(context, view)
  local cb = context.clipboard
  if not cb then
    core.message.warning('No clipboard')
    return
  end

  local item = view:get_item(vim.fn.line('.'))
  local dest = (item.isdirectory and item.opened) and item or item.parent
  if cb:paste(dest) and cb.hold then
    context.clipboard = nil
  end
  view:draw(context)
end

function M.quit(context, view)
  VFiler.delete(view.bufnr)
end

function M.redraw(context, view)
  view:draw(context)
end

function M.redraw_all(context, view)
  for _, filer in ipairs(VFiler.get_displays()) do
    M.redraw(filer.context, filer.view)
  end
end

function M.reload(context, view)
  context:update()
  view:draw(context)
end

function M.reload_all(context, view)
  for _, filer in ipairs(VFiler.get_displays()) do
    M.reload(filer.context, filer.view)
  end
end

function M.rename(context, view)
  local selected = view:selected_items()
  if #selected == 1 then
    rename_one_file(context, view, selected[1])
  elseif #selected > 1 then
    rename_files(context, view, selected)
  end
end

function M.switch_to_drive(context, view)
  if context.extension then
    return
  end

  local drives = detect_drives()
  if #drives == 0 then
    return
  end

  local root = context.root:root()
  local menu = Menu.new {
    name = 'Select Drive',
    on_selected = function(drive)
      if root == drive then
        return
      end

      context:save(view:get_current().path)
      local path = context:switch_drive(drive, true)
      view:draw(context)
      -- Skip header line
      move_cursor(math.max(view:indexof(path), 2))
    end,
    on_quit = function()
      context.extension = nil
    end,
  }

  menu:start(drives, root)
  context.extension = menu
end

function M.switch_to_filer(context, view)
  local current = VFiler.get_current()
  -- already linked
  if current.linked then
    current.linked:open('right')
    return
  end

  core.window.open('right')
  local filer = VFiler.new(current.configs)
  cd(filer.context, filer.view, context.root.path)
  filer:link(current)
  
  -- redraw current
  current:open()
  M.redraw(current.context, current.view)
  filer:open()
end

function M.toggle_show_hidden(context, view)
  view.show_hidden_files = not view.show_hidden_files
  view:draw(context)
end

function M.toggle_select(context, view)
  local lnum = vim.fn.line('.')
  local item = view:get_item(lnum)
  item.selected = not item.selected
  view:redraw_line(lnum)
end

function M.toggle_select_all(context, view)
  for _, item in ipairs(context.root:walk()) do
    item.selected = not item.selected
  end
  view:redraw()
end

function M.toggle_select_down(context, view)
  M.toggle_select(context, view)
  M.move_cursor_down(context, view)
end

function M.toggle_select_up(context, view)
  M.toggle_select(context, view)
  M.move_cursor_up(context, view)
end

function M.yank_name(context, view)
  local names = {}
  for _, selected in ipairs(view:selected_items()) do
    table.insert(names, selected.name)
  end
  if #names == 1 then
    Clipboard.yank(names[1])
    core.message.info('Yanked name - "%s"', names[1])
  elseif #names > 1 then
    local content = table.concat(names, '\n')
    Clipboard.yank(content)
    core.message.info('Yanked %d names', #names)
  end
end

function M.yank_path(context, view)
  local paths = {}
  for _, selected in ipairs(view:selected_items()) do
    table.insert(paths, selected.path)
  end
  if #paths == 1 then
    Clipboard.yank(paths[1])
    core.message.info('Yanked path - "%s"', paths[1])
  elseif #paths > 1 then
    local content = table.concat(paths, '\n')
    Clipboard.yank(content)
    core.message.info('Yanked %d paths', #paths)
  end
end

return M
