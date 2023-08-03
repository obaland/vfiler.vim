local vim = require('vfiler/libs/vim')

local Timer = {}
Timer.__index = Timer

local function create_result_data(laptimes)
  if #laptimes == 0 then
    return {}
  end
  -- Create result data
  local lap = laptimes[1]
  local times = {
    {
      mark = lap.mark,
      time = lap.time,
      total = lap.time,
    },
  }
  local prev = lap
  for i = 2, #laptimes do
    lap = laptimes[i]
    table.insert(times, {
      mark = lap.mark,
      time = lap.time - prev.time,
      total = lap.time,
    })
    prev = lap
  end
  return times
end

function Timer.start(name)
  return setmetatable({
    _name = name,
    _laptimes = {},
    _start = vim.fn.reltime(),
  }, Timer)
end

function Timer:lap(mark)
  local time = vim.fn.reltimefloat(vim.fn.reltime(self._start))
  table.insert(self._laptimes, {
    mark = mark,
    time = time,
  })
  return time
end

function Timer:print()
  local times = create_result_data(self._laptimes)

  -- Print result data
  print('---', self._name, '---')
  print('No\tMark\tTime(s)\tTotal')
  for i, time in ipairs(times) do
    local result = ('%d\t%s\t%.6f\t%.6f'):format(
      i,
      time.mark,
      time.time,
      time.total
    )
    print(result)
  end
end

function Timer:write(path)
  local times = create_result_data(self._laptimes)
  local file, error = io.open(path, 'w')
  if not file then
    print(error)
    return
  end
  file:write('No,Mark,Time(s),Total\n')
  for i, time in ipairs(times) do
    file:write(
      ('%d,%s,%.6f,%.6f\n'):format(i, time.mark, time.time, time.total)
    )
  end
  file:close()
end

return Timer
