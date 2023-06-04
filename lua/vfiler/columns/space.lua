local core = require('vfiler/libs/core')

local SpaceColumn = {}

function SpaceColumn.new()
  local Column = require('vfiler/columns/column')
  return core.inherit(SpaceColumn, Column)
end

function SpaceColumn:get_text(item, width, winid)
  return ' ', 1
end

function SpaceColumn:get_width(items, width, winid)
  return 1
end

return SpaceColumn
