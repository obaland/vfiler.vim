local core = require 'vfiler/core'
local Column = require 'vfiler/columns/column'

local IndentColumn = {}

function IndentColumn.new()
  local self = core.inherit(IndentColumn, Column, 'indent')
  self.variable = true
  self.icon = '|'
  return self
end

function IndentColumn:highlights()
  return self._syntax:highlights()
end

function IndentColumn:syntaxes()
  return self._syntax:syntaxes()
end

return IndentColumn
