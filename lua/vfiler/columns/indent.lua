local core = require 'vfiler/core'
local Column = require 'vfiler/columns/column'

local IconColumn = {}

function IconColumn.new()
  local self = core.inherit(IconColumn, Column, 'icon')
  return self
end

return IconColumn
