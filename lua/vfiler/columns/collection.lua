local IconColumn = require 'vfiler/columns/icon'
local IndentColumn = require 'vfiler/columns/indent'
local NameColumn = require 'vfiler/columns/name'

local M = {}

local columns = {
  icon = IconColumn.new(),
  indent = IndentColumn.new(),
  name = NameColumn.new(),
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
