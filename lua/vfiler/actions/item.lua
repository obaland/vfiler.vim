local cmdline = require('vfiler/libs/cmdline')
local core = require('vfiler/libs/core')
local util = require('vfiler/actions/utility')

local Clipboard = require('vfiler/clipboard')
local Menu = require('vfiler/extensions/menu')

local M = {}

local function get_mount_path()
  return core.is_mac and '/Volumes' or '/mnt'
end

local function detect_drives()
  local drives = {}
  if core.is_windows then
    for byte = ('A'):byte(), ('Z'):byte() do
      local drive = string.char(byte) .. ':/'
      if core.path.is_directory(drive) then
        table.insert(drives, drive)
      end
    end
  else
    local mount = core.path.join(get_mount_path(), '*')
    for _, path in ipairs(vim.fn.glob(mount, 1, 1)) do
      if core.path.is_directory(path) then
        table.insert(drives, vim.fn.fnamemodify(path, ':t'))
      end
    end
    table.sort(drives)
  end
  return drives
end

function M.change_to_parent(vfiler, context, view)
  local current_path = context.root.path
  util.cd(vfiler, context, view, context:parent_path(), function()
    view:move_cursor(current_path)
  end)
end

function M.clear_selected_all(vfiler, context, view)
  for _, item in ipairs(view:selected_items()) do
    item.selected = false
  end
  view:redraw()
end

function M.jump_to_directory(vfiler, context, view)
  local dirpath = cmdline.input('Jump to?', '', 'dir')
  if #dirpath == 0 then
    return
  end
  dirpath = core.path.normalize(dirpath)
  if not core.path.is_directory(dirpath) then
    core.message.error('Not exists the "%s" path.', dirpath)
    return
  end
  util.cd(vfiler, context, view, dirpath)
end

function M.jump_to_home(vfiler, context, view)
  local dirpath = vim.fn.expand('~')
  util.cd(vfiler, context, view, dirpath)
end

function M.jump_to_root(vfiler, context, view)
  local dirpath = core.path.root(context.root.path)
  util.cd(vfiler, context, view, dirpath)
end

function M.toggle_select(vfiler, context, view)
  local lnum = vim.fn.line('.')
  local item = view:get_item(lnum)
  if item then
    item.selected = not item.selected
    view:redraw_line(lnum)
  end
end

function M.toggle_select_all(vfiler, context, view)
  for item in view:walk_items() do
    item.selected = not item.selected
  end
  view:redraw()
end

function M.close_tree(vfiler, context, view)
  local item = view:get_current()
  local target = (item.is_directory and item.opened) and item or item.parent

  target:close()
  view:draw(context)
  view:move_cursor(target.path)
end

function M.close_tree_or_cd(vfiler, context, view)
  local item = view:get_current()
  local level = item and item.level or 0
  if level == 0 or (level <= 1 and not item.opened) then
    local path = context.root.path
    util.cd(vfiler, context, view, context:parent_path(), function()
      view:move_cursor(path)
    end)
  else
    M.close_tree(vfiler, context, view)
  end
end

function M.open(vfiler, context, view)
  local path = view:get_current().path
  util.open_file(vfiler, context, view, path)
end

function M.open_by_choose(vfiler, context, view)
  local path = view:get_current().path
  util.open_file(vfiler, context, view, path, 'choose')
end

function M.open_by_choose_or_cd(vfiler, context, view)
  local item = view:get_current()
  if item.is_directory then
    util.cd(vfiler, context, view, item.path)
  else
    util.open_file(vfiler, context, view, item.path, 'choose')
  end
end

function M.open_by_split(vfiler, context, view)
  local path = view:get_current().path
  util.open_file(vfiler, context, view, path, 'bottom')
end

function M.open_by_tabpage(vfiler, context, view)
  local path = view:get_current().path
  util.open_file(vfiler, context, view, path, 'tab')
end

function M.open_by_vsplit(vfiler, context, view)
  local path = view:get_current().path
  util.open_file(vfiler, context, view, path, 'right')
end

function M.open_tree(vfiler, context, view)
  local lnum = vim.fn.line('.')
  local item = view:get_item(lnum)
  if not item.is_directory or item.opened then
    return
  end
  item:open()
  view:draw(context)
  core.cursor.move(lnum + 1)
end

function M.open_tree_recursive(vfiler, context, view)
  local lnum = vim.fn.line('.')
  local item = view:get_item(lnum)
  if not item.is_directory or item.opened then
    return
  end
  item:open(true)
  view:draw(context)
  core.cursor.move(lnum + 1)
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
  util.start_extension(vfiler, context, view, menu)
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
