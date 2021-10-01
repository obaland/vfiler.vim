local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local ListExtension = require 'vfiler/extensions/list'

local actions = {}

local M = {}

function M.do_action(name, context, view, args)
  if not actions[name] then
    core.error(string.format('Action "%s" is not defined', name))
    return
  end
  actions[name](context, view, args)
end

function M.define(name, func)
  actions[name] = func
end

function M.undefine(name, func)
  actions[name] = nil
end

------------------------------------------------------------------------------
-- actions
------------------------------------------------------------------------------
local function detect_drives()
  if not core.is_windows then
    return {}
  end
  local drives = {}
  for byte = ('A'):byte(), ('Z'):byte() do
    local drive = string.char(byte) .. ':/'
    if vim.fn.isdirectory(drive) then
      table.insert(drives, drive)
    end
  end
  return drives
end

local function move_cursor(lnum)
  vim.fn.cursor(lnum, 1)
end

function actions.cd(context, view, args)
  -- special path
  local path = args[1]
  if path == '..' then
    -- change parent directory
    path = vim.fn.fnamemodify(context.path, ':h')
  end
  context:switch(path)
  view:draw(context)
end

function actions.open(context, view, args)
  local lnum = args[1] or vim.fn.line('.')
  local item = context:get_item(lnum)
  if not item then
    core.warning('Item does not exist.')
    return
  end

  if item.isdirectory then
    actions.cd(context, view, {item.path})
  else
    vim.command('edit ' .. item.path)
  end
end

function actions.close_tree(context, view, args)
  local lnum = args[1] or vim.fn.line('.')
  local pos = context:close_directory(lnum)
  if pos then
    move_cursor(pos)
    view:draw(context)
  end
end

function actions.close_tree_or_cd(context, view, args)
  local lnum = args[1] or vim.fn.line('.')
  local item = context:get_item(lnum)
  if item.level <= 1 and not item.opened then
    actions.cd(context, view, {'..'})
  else
    actions.close_tree(context, view, {lnum})
  end
end

function actions.open_tree(context, view, args)
  local lnum = args[1] or vim.fn.line('.')
  local pos = context:open_directory(lnum)
  if pos then
    move_cursor(pos + 1)
    view:draw(context)
  end
end

function actions.start(context, view, args)
  mapping.define('main')

  local path = args[1]
  context:switch(path)
  view:draw(context)
end

function actions.change_drive(context, view, args)
  local extension = ListExtension.new('drives')
  extension.on_selected = function()
  end
  extension.run(detect_drives(), context.configs.extensions)
  context.extension = extension
end

return M
