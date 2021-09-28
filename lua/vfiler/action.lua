local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

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

function actions.cd(context, view, args)
  -- special path
  local path = args[1]
  if path == '..' then
    -- change parent directory
    path = vim.fn.fnamemodify(context.path, ':h')
  end
  print(path)
  context:switch(path)
  view:draw(context)
end

function actions.move_cursor(context, view, lnum)
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
  local item = context:get_item(lnum)
  if item.level <= 0 and not item.opened then
    actions.cd(context, view, {'..'})
  else
    context:close_directory(lnum)
  end
  view:draw(context)
end

function actions.open_tree(context, view, args)
  local lnum = args[1] or vim.fn.line('.')
  context:open_directory(lnum)
  view:draw(context)
end

function actions.start(context, view, args)
  mapping.define()

  local path = args[1]
  context:switch(path)
  view:draw(context)
end

return M
