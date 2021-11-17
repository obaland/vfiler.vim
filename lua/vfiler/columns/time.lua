local core = require 'vfiler/core'

local TimeColumn = {}

function TimeColumn.new()
  local Column = require('vfiler/columns/column')
  local self = core.inherit(TimeColumn, Column, 'time')
  self.format = '%Y/%m/%d %H:%M'

  local Syntax = require('vfiler/columns/syntax')
  self._syntax = Syntax.new {
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
    ignore_group = 'vfilerType_Ignore',
  }
  return self
end

function TimeColumn:get_text(item, width)
  local key = 'other'
  local difftime = os.difftime(os.time(), item.time)

  if difftime < 86400 then
    -- 1day (60 * 60 * 24 = 86400)
    key = 'today'
  elseif difftime < 604800 then
    -- 1week (86400 * 7 = 604800)
    key = 'week'
  end
  return self._syntax:surround_text(key, os.date(self.format, item.time))
end

function TimeColumn:get_width(items, width)
  return #os.date(self.format, 0)
end

return TimeColumn
