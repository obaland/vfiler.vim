local core = require('vfiler/libs/core')

local SizeColumn = {}

function SizeColumn.new()
  local Column = require('vfiler/columns/column')
  local self = core.inherit(SizeColumn, Column, {
    {
      group = 'vfilerSize',
      name = 'size',
      region = {
        start_mark = 's</',
        end_mark = '/>s.',
      },
    },
  })
  -- NOTE: value(6) + space(1) + unit(2)
  self._width = 9
  return self
end

function SizeColumn:to_text(item, width)
  if item.type == 'directory' then
    return {
      string = (' '):rep(self._width),
      width = self._width,
    }
  end

  local byte_unit = 'B '
  local size = item.size
  local format = '%6d'

  if size >= 1024 then
    local byte_units = { 'KB', 'MB', 'GB', 'TB', 'PB' }
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
  return {
    string = format:format(size) .. ' ' .. byte_unit,
    width = self._width,
    syntax = 'size',
  }
end

function SizeColumn:get_width(items, width, winid)
  return self._width
end

return SizeColumn
