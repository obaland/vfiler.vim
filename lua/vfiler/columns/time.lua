local core = require('vfiler/libs/core')

local TimeColumn = {}

function TimeColumn.new()
  local Column = require('vfiler/columns/column')
  local self = core.inherit(TimeColumn, Column, {
    syntaxes = {
      today = {
        group = 'vfilerTime_Today',
        start_mark = 't@t\\',
        highlight = 'vfilerTimeToday',
      },
      week = {
        group = 'vfilerTime_Week',
        start_mark = 't@w\\',
        highlight = 'vfilerTimeWeek',
      },
      other = {
        group = 'vfilerTime_Other',
        start_mark = 't@o\\',
        highlight = 'vfilerTime',
      },
    },
    end_mark = '\\t@',
  })
  self.format = '%Y/%m/%d %H:%M'
  return self
end

function TimeColumn:get_width(items, width)
  return #os.date(self.format, 0)
end

function TimeColumn:_get_text(item, width)
  return os.date(self.format, item.time)
end

function TimeColumn:_get_syntax_name(item, width)
  local key
  local difftime = os.difftime(os.time(), item.time)
  if difftime < 86400 then
    -- 1day (60 * 60 * 24 = 86400)
    key = 'today'
  elseif difftime < 604800 then
    -- 1week (86400 * 7 = 604800)
    key = 'week'
  else
    key = 'other'
  end
  return key
end

return TimeColumn
