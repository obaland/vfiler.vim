local core = require 'vfiler/core'

local SpaceColumn = {}

function SpaceColumn.new()
  local Column = require('vfiler/columns/column')
  return core.inherit(SpaceColumn, Column, 'sp')
end

function SpaceColumn:get_text(context, lnum, width)
  return ' ', 1
end

function SpaceColumn:get_width(context, width)
  return 1
end

return SpaceColumn
