local core = require('vfiler/libs/core')

local TimeColumn = {}

function TimeColumn.new()
  local end_mark = '/>e'

  local Column = require('vfiler/columns/column')
  local self = core.inherit(TimeColumn, Column, {
    {
      group = 'vfilerTime_Today',
      name = 'today',
      region = {
        start_mark = 'e.~</',
        end_mark = end_mark,
      },
      highlight = 'vfilerTimeToday',
    },
    {
      group = 'vfilerTime_Week',
      name = 'week',
      region = {
        start_mark = 'e.,</',
        end_mark = end_mark,
      },
      highlight = 'vfilerTimeWeek',
    },
    {
      group = 'vfilerTime_Other',
      name = 'other',
      region = {
        start_mark = 'e..</',
        end_mark = end_mark,
      },
      highlight = 'vfilerTime',
    },
  })
  self.format = '%Y/%m/%d %H:%M'
  return self
end

function TimeColumn:get_text(item, width)
  local syntax = 'other'
  local difftime = os.difftime(os.time(), item.time)
  if difftime < 86400 then
    -- 1day (60 * 60 * 24 = 86400)
    syntax = 'today'
  elseif difftime < 604800 then
    -- 1week (86400 * 7 = 604800)
    syntax = 'week'
  end

  local text = os.date(self.format, item.time)
  return self:surround_text(syntax, text), vim.fn.strwidth(text)
end

function TimeColumn:get_width(items, width)
  return #os.date(self.format, 0)
end

return TimeColumn
