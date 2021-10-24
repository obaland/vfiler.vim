local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local sort = require 'vfiler/sort'
local vim = require 'vfiler/vim'

local ExtensionMenu = require 'vfiler/extensions/menu'
local File = require 'vfiler/items/file'
local VFiler = require 'vfiler/vfiler'

local M = {}

local function detect_drives()
  if not core.is_windows then
    return {}
  end
  local drives = {}
  for byte = ('A'):byte(), ('Z'):byte() do
    local drive = string.char(byte) .. ':/'
    if vim.fn.isdirectory(drive) == 1 then
      table.insert(drives, drive)
    end
  end
  return drives
end

local function input_names(message)
  local content = core.input(message)
  return vim.fn.split(content, [[\s*,\s*]])
end

-- @param lnum number
local function move_cursor(lnum)
  vim.fn.cursor(lnum, 1)
end

------------------------------------------------------------------------------
-- interfaces
------------------------------------------------------------------------------
function M.define(name, func)
  M[name] = func
end

function M.do_action(name, ...)
  if not M[name] then
    core.error(string.format('Action "%s" is not defined', name))
    return
  end

  local vfiler = VFiler.get(vim.fn.bufnr())
  if not vfiler then
    core.error('Buffer does not exist.')
    return
  end
  M[name](vfiler.context, vfiler.view, ...)
end

function M.start(configs)
  local vfiler = VFiler.new(configs)
  mapping.define('main')
  M.cd(vfiler.context, vfiler.view, configs.path)
  move_cursor(2)
end

function M.undefine(name)
  M[name] = nil
end

------------------------------------------------------------------------------
-- actions
------------------------------------------------------------------------------
function M.cd(context, view, path)
  -- special path
  if path == '..' then
    -- change parent directory
    path = vim.fn.fnamemodify(context.path, ':h')
  end
  context:switch(path)
  view:draw(context)
end

function M.new_file(context, view)
  local dir = context:get_directory_path(vim.fn.line('.'))
  local names = input_names('New file names? (comma separated)')
  if #names == 0 then
    core.info('Canceled')
    return
  end

  for _, name in ipairs(names) do
    local path = dir .. '/' .. name
    if vim.fn.filereadable(path) ~= 0 then
      core.warning(('Skipped, %s already exists'):format(name))
    else
      local file = File.create(path)
      if file then
      else
      end
    end
  end
end

function M.close_tree(context, view, lnum)
  lnum = lnum or vim.fn.line('.')
  local item = view:get_item(lnum)

  local parent = item.parent
  parent:close()

  view:draw(context)

  local cursor = view:indexof(parent)
  if cursor then
    move_cursor(cursor)
  end
end

function M.close_tree_or_cd(context, view, lnum)
  lnum = lnum or vim.fn.line('.')
  local item = view:get_item(lnum)
  if item.level <= 1 and not item.opened then
    M.cd(context, view, '..')
  else
    M.close_tree(context, view, lnum)
  end
end

function M.change_drive(context, view)
  if context.extension then
    return
  end

  local drives = detect_drives()
  if #drives == 0 then
    return
  end

  local root = core.get_root_path(context.path)
  local cursor = 1
  for i, drive in ipairs(drives) do
    if drive == root then
      cursor = i
      break
    end
  end

  local menu = ExtensionMenu.new('Select Drive', context)
  menu.on_selected = function(ctx, item)
    M.cd(ctx, view, item)
  end

  menu:start(drives, cursor)
  context.extension = menu
end

function M.change_sort(context, view)
  if context.extension then
    return
  end

  local sort_types = sort.types()
  local cursor = 1
  for i, type in ipairs(sort_types) do
    if type == context.sort then
      cursor = i
      break
    end
  end

  local menu = ExtensionMenu.new('Select Sort', context)
  menu.on_selected = function(ctx, item)
    if ctx.sort ~= item then
      ctx:change_sort(item)
      view:draw(ctx)
    end
  end
  menu:start(sort_types, cursor)
  context.extension = menu
end

function M.move_cursor_bottom(context, view)
  move_cursor(view:num_lines())
end

function M.move_cursor_down(context, view, loop)
  loop = loop or false
  local lnum = vim.fn.line('.') + 1
  local num_end = view:num_lines()
  if lnum > num_end then
    -- the meaning of "2" is to skip the header line
    lnum = loop and 2 or num_end
  end
  move_cursor(lnum)
end

function M.move_cursor_top(context, view)
  move_cursor(2)
end

function M.move_cursor_up(context, view, loop)
  loop = loop or false
  local lnum = vim.fn.line('.') - 1
  if lnum <= 1 then
    -- the meaning of "2" is to skip the header line
    lnum = loop and view:num_lines() or 2
  end
  move_cursor(lnum)
end

function M.open(context, view, lnum)
  lnum = lnum or vim.fn.line('.')
  local item = view:get_item(lnum)
  if not item then
    core.warning('Item does not exist.')
    return
  end

  if item.isdirectory then
    M.cd(context, view, item.path)
  else
    vim.command('edit ' .. item.path)
  end
end

function M.open_tree(context, view, lnum)
  lnum = lnum or vim.fn.line('.')
  local item = view:get_item(lnum)

  if not item.isdirectory or item.opened then
    return
  end
  item:open(context.sort)
  view:draw(context)
  move_cursor(lnum + 1)
end

function M.quit(context, view)
  VFiler.delete(context.buffer.number)
end

function M.redraw(context, view)
  view:draw(context)
end

function M.switch_to_buffer(context, view)
  -- already linked
  if context.linked then
    context.linked.buffer:open('right')
    return
  end

  core.open_window('right')

  local duplicated = VFiler.duplicate(context.buffer.number)
  mapping.define('main')
  M.cd(duplicated.context, duplicated.view, context.path)
  duplicated.context:link(context)
end

return M
