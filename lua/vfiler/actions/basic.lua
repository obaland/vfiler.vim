local api = require('vfiler/actions/api')
local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local Menu = require('vfiler/extensions/menu')
local VFiler = require('vfiler/vfiler')

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

function M.clear_selected_all(vfiler, context, view)
  for _, item in ipairs(view:selected_items()) do
    item.selected = false
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
    api.cd(vfiler, context, view, context:parent_path(), function()
      view:move_cursor(path)
    end)
  else
    M.close_tree(vfiler, context, view)
  end
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

function M.open(vfiler, context, view)
  local path = view:get_current().path
  api.open_file(vfiler, context, view, path, 'edit')
end

function M.open_by_choose(vfiler, context, view)
  local path = view:get_current().path
  api.open_file(vfiler, context, view, path, 'choose')
end

function M.open_by_choose_or_cd(vfiler, context, view)
  local item = view:get_current()
  if item.is_directory then
    api.cd(vfiler, context, view, item.path)
  else
    api.open_file(vfiler, context, view, item.path, 'choose')
  end
end

function M.open_by_split(vfiler, context, view)
  local path = view:get_current().path
  api.open_file(vfiler, context, view, path, 'bottom')
end

function M.open_by_tabpage(vfiler, context, view)
  local path = view:get_current().path
  api.open_file(vfiler, context, view, path, 'tab')
end

function M.open_by_vsplit(vfiler, context, view)
  local path = view:get_current().path
  api.open_file(vfiler, context, view, path, 'right')
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

function M.quit(vfiler, context, view)
  api.close_preview(vfiler, context, view)
  vfiler:quit()
end

function M.redraw(vfiler, context, view)
  context:reload_gitstatus(function()
    view:draw(context)
  end)
  api.open_preview(vfiler, context, view)
end

function M.reload(vfiler, context, view)
  context:save(view:get_current().path)
  context:switch(context.root.path, function(ctx)
    view:draw(ctx)
  end)
  api.open_preview(vfiler, context, view)
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
  api.start_extension(vfiler, context, view, menu)
end

function M.switch_to_filer(vfiler, context, view)
  -- close preview window
  api.close_preview(vfiler, context, view)

  local linked = context.linked
  -- already linked
  if linked then
    if linked:displayed() then
      linked:focus()
    else
      linked:open('right')
    end
    linked:do_action(api.open_preview)
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
  vfiler:focus()
  view:draw(context)

  newfiler:focus() -- return other filer
  newfiler:do_action(api.open_preview)
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

return M
