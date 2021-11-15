local M = {}

local columns = {
  icon = require('vfiler/columns/icon').new(),
  indent = require('vfiler/columns/indent').new(),
  mode = require('vfiler/columns/mode').new(),
  name = require('vfiler/columns/name').new(),
  size = require('vfiler/columns/size').new(),
  space = require('vfiler/columns/space').new(),
  time = require('vfiler/columns/time').new(),
  type = require('vfiler/columns/type').new(),
}

function M.get(name)
  return columns[name]
end

function M.register(column)
  columns[column.name] = column
end

function M.unregister(name)
  columns[name] = nil
end

return M
