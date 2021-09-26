local core = require 'vfiler/core'

local Column = require 'vfiler/columns/column'
local Syntax = require 'vfiler/columns/syntax'

local SizeColumn = {}

function SizeColumn.new()
  local self = core.inherit(SizeColumn, Column, 'size')
  -- Note: value(6) + space(1) + unit(2)
  self._width = 9

  self._syntax = Syntax.new {
    syntaxes = {
      size = {
        group = 'vfilerSize',
        start_mark = 's@\\',
      },
    },
    end_mark = '\\s@',
    ignore_group = 'vfilerName_Ignore',
  }
  return self
end

function SizeColumn:get_text(context, lnum, width)
  local item = context:get_item(lnum)
  if item.isdirectory then
    return (' '):rep(self._width), self._width
  end

  local byte_unit = 'B '
  local size = item.size
  local format = '%6d'

  if size >= 1024 then
    local byte_units = {'KB', 'MB', 'GB', 'TB'}
    size = size / 1024.0
    for _, unit in ipairs(byte_units) do
      if size < 1024.0 then
        byte_unit = unit
        break
      end
      size = size / 1024.0
    end

    local integer = math.modf(size)
    if integer >= 1000 then
      format = '%4.1f'
    elseif integer >= 100 then
      format = '%3.2f'
    elseif integer >= 10 then
      format = '%2.3f'
    else
      format = '%1.4f'
    end
  end
  return self._syntax:surround_text(
    'size', format:format(size) .. ' ' .. byte_unit
  )
end

function SizeColumn:get_width(context, width)
  return self._width
end

function SizeColumn:highlights()
  return self._syntax:highlights()
end

function SizeColumn:syntaxes()
  return self._syntax:syntaxes()
end

return SizeColumn
