local actions = {}

local M = {}

function M.register(name, func)
  actions[name] = func
end

function M.unregister(name, func)
  actions[name] = nil
end

function actions.move_cursor(lnum)
end
