local api = require('vfiler/actions/api')
local cmdline = require('vfiler/libs/cmdline')
local core = require('vfiler/libs/core')

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
  api.cd(vfiler, context, view, context:parent_path())
  view:move_cursor(current_path)
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
  api.cd(vfiler, context, view, dirpath)
end

function M.jump_to_home(vfiler, context, view)
  local dirpath = vim.fn.expand('~')
  api.cd(vfiler, context, view, dirpath)
end

function M.jump_to_root(vfiler, context, view)
  local dirpath = core.path.root(context.root.path)
  api.cd(vfiler, context, view, dirpath)
end

function M.close_tree(vfiler, context, view)
  local item = view:get_item()
  local target = item.opened and item or item.parent

  target:close()
  view:draw(context)
  view:move_cursor(target.path)
  context:save(target.path)
end

function M.close_tree_or_cd(vfiler, context, view)
  local item = view:get_item()
  local level = item and item.level or 0
  if level == 0 or (level <= 1 and not item.opened) then
    local path = context.root.path
    api.cd(vfiler, context, view, context:parent_path())
    view:move_cursor(path)
  else
    M.close_tree(vfiler, context, view)
  end
end

function M.open_tree(vfiler, context, view)
  local lnum = vim.fn.line('.')
  local item = view:get_item(lnum)
  if item.type ~= 'directory' or item.opened then
    return
  end
  item:open()
  view:draw(context)
  lnum = lnum + 1
  core.cursor.move(lnum)
  context:save(view:get_item(lnum).path)
end

function M.open_tree_recursive(vfiler, context, view)
  local lnum = vim.fn.line('.')
  local item = view:get_item(lnum)
  if item.type ~= 'directory' or item.opened then
    return
  end
  item:open(true)
  view:draw(context)
  lnum = lnum + 1
  core.cursor.move(lnum)
  context:save(view:get_item(lnum).path)
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

      ctx:save(v:get_item().path)
      local focus_path = ctx:switch_drive(drive)
      v:draw(ctx)
      v:move_cursor(focus_path)
    end,
  })
  api.start_extension(vfiler, context, view, menu)
end

return M
