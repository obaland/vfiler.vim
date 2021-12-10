local core = require('vfiler/core')

local SpaceColumn = {}

function SpaceColumn.new()
  local Column = require('vfiler/columns/column')
  return core.inherit(SpaceColumn, Column, 'space')
end

function SpaceColumn:get_text(item, width)
  return ' ', 1
end

function SpaceColumn:get_width(items, width)
  return 1
end

return SpaceColumn
