local core = require 'vfiler/core'
local exaction = require 'vfiler/extensions/action'
local mapping = require 'vfiler/mapping'
local sort = require 'vfiler/sort'
local vim = require 'vfiler/vim'

local Buffer = require 'vfiler/buffer'
local ExtensionMenu = require 'vfiler/extensions/menu'

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

function M.do_action(name, args)
  if not M[name] then
    core.error(string.format('Action "%s" is not defined', name))
    return
  end

  local buffer = Buffer.get(vim.fn.bufnr())
  if not buffer then
    core.error('Buffer does not exist.')
    return
  end
  M[name](buffer.context, buffer.view, args)
end

function M.start(configs)
  local buffer = Buffer.new(configs)
  mapping.define('main')

  buffer.context:switch(configs.path)
  buffer.view:draw(buffer.context)
end

function M.undefine(name)
  M[name] = nil
end

------------------------------------------------------------------------------
-- actions
------------------------------------------------------------------------------
function M.cd(context, view, args)
  -- special path
  local path = args[1]
  if path == '..' then
    -- change parent directory
    path = vim.fn.fnamemodify(context.path, ':h')
  end
  context:switch(path)
  view:draw(context)
end

function M.open(context, view, args)
  local lnum = args[1] or vim.fn.line('.')
  local item = context:get_item(lnum)
  if not item then
    core.warning('Item does not exist.')
    return
  end

  if item.isdirectory then
    M.cd(context, view, {item.path})
  else
    vim.command('edit ' .. item.path)
  end
end

function M.close_tree(context, view, args)
  local lnum = args[1] or vim.fn.line('.')
  local pos = context:close_directory(lnum)
  if pos then
    move_cursor(pos)
    view:draw(context)
  end
end

function M.close_tree_or_cd(context, view, args)
  local lnum = args[1] or vim.fn.line('.')
  local item = context:get_item(lnum)
  if item.level <= 1 and not item.opened then
    M.cd(context, view, {'..'})
  else
    M.close_tree(context, view, {lnum})
  end
end

function M.open_tree(context, view, args)
  local lnum = args[1] or vim.fn.line('.')
  local pos = context:open_directory(lnum)
  if pos then
    move_cursor(pos + 1)
    view:draw(context)
  end
end

function M.change_drive(context, view, args)
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
  menu.on_selected = function(item)
    M.cd(context, view, {item})
  end

  menu:start(drives, cursor)
  context.extension = menu
end

function M.change_sort(context, view, args)
  local sort_types = sort.types()
  local cursor = 1
  for i, type in ipairs(sort_types) do
    if type == context.sort then
      cursor = i
      break
    end
  end

  local menu = ExtensionMenu.new('Select Sort', context)
  menu.on_selected = function(item)
    if context.sort ~= item then
      context:change_sort(item)
      view:draw(context)
    end
  end
  menu:start(sort_types, cursor)
  context.extension = menu
end

function M.move_cursor_bottom(context, view, args)
  move_cursor(#context.items)
end

function M.move_cursor_down(context, view, args)
  local loop = (#args > 0) and args[1] or false
  local lnum = vim.fn.line('.') + 1
  local num_end = #context.items
  if lnum > num_end then
    -- the meaning of "2" is to skip the header line
    lnum = loop and 2 or num_end
  end
  move_cursor(lnum)
end

function M.move_cursor_top(context, view, args)
  move_cursor(2)
end

function M.move_cursor_up(context, view, args)
  local loop = (#args > 0) and args[1] or false
  local lnum = vim.fn.line('.') - 1
  if lnum <= 1 then
    -- the meaning of "2" is to skip the header line
    lnum = loop and #context.items or 2
  end
  move_cursor(lnum)
end

function M.switch_to_buffer(context, view, args)
end

return M
