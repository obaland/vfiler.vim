local core = require 'vfiler/core'
local Column = require 'vfiler/columns/column'

local NameColumn = {}

function NameColumn.new()
  local self = core.inherit(NameColumn, Column, 'name')
  return self
end

return NameColumn
