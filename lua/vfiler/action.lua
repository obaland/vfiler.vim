local core = require 'vfiler/core'

local actions = {}

local M = {}

function M.do_action(name, context, view, ...)
  if not actions[name] then
    core.error(string.format('Action "%s" is not defined', name))
    return
  end
  actions[name](context, view, ...)
end

function M.define(name, func)
  actions[name] = func
end

function M.undefine(name, func)
  actions[name] = nil
end

function actions.move_cursor(context, view, lnum)
end

function actions.start(context, view, path)
  context:switch(path)
end

return M
