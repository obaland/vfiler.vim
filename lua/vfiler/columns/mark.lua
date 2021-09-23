local core = require 'vfiler/core'
local Column = require 'vfiler/columns/column'

local MarkColumn = {}

function MarkColumn.new()
  local self = core.inherit(MarkColumn, Column, 'mark')
  return self
end

return MarkColumn
