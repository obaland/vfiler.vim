local IconColumn = require 'vfiler/columns/icon'
local IndentColumn = require 'vfiler/columns/indent'
local ModeColumn = require 'vfiler/columns/mode'
local NameColumn = require 'vfiler/columns/name'
local SizeColumn = require 'vfiler/columns/size'
local SpaceColumn = require 'vfiler/columns/space'
local TimeColumn = require 'vfiler/columns/time'

local M = {}

local columns = {
  icon = IconColumn.new(),
  indent = IndentColumn.new(),
  mode = ModeColumn.new(),
  name = NameColumn.new(),
  size = SizeColumn.new(),
  sp = SpaceColumn.new(),
  time = TimeColumn.new(),
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
