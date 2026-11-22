local core = require('vfiler/libs/core')

local TimeColumn = { partial_redraw = true }

local DAY = 86400
local WEEK = 604800

local function age_syntax(age)
  if age < DAY then
    return 'today'
  elseif age < WEEK then
    return 'week'
  end
  return 'other'
end

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

function TimeColumn:needs_redraw(items, drawn_at)
  local now = os.time()
  if now == drawn_at then
    return false
  end

  local first = math.min(now, drawn_at)
  local last = math.max(now, drawn_at)
  local day_start, day_end = first - DAY, last - DAY
  local week_start, week_end = first - WEEK, last - WEEK

  for _, item in ipairs(items) do
    local time = item.time
    if
      (day_start < time and time <= day_end)
      or (week_start < time and time <= week_end)
    then
      return true
    end
  end
  return false
end

function TimeColumn:to_text(item, width)
  local syntax = age_syntax(os.difftime(os.time(), item.time))
  local text = os.date(self.format, item.time)
  return {
    string = text,
    width = vim.fn.strwidth(text),
    syntax = syntax,
  }
end

function TimeColumn:get_width(items, width, winid)
  return #os.date(self.format, 0)
end

return TimeColumn
