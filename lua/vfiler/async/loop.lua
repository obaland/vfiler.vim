local vim = require('vfiler/vim')

local Loop = {}
Loop.__index = Loop

local timers = {}

local MAX_ID = 65535
local latest_id = 1

function Loop.new(options)
  local self = setmetatable({
    _id = nil,
    interval = 0,
  }, Loop)
  for key, value in pairs(options) do
    self[key] = value
  end
  return self
end

function Loop._callback(id)
  local timer = timers[id]
  if not timer then
    return
  end
  if timer.callback then
    timer.callback()
  end
end

function Loop:start()
  -- assgin and update id
  self._id = latest_id
  latest_id = math.min(latest_id + 1, MAX_ID)
  timers[self._id] = self
  self._timer = vim.fn['vfiler#timer#start'](self.interval)
end

function Loop:stop()
  if self._id then
    vim.fn['vfiler#timer#stop'](self._timer)
    self._id = nil
  end
end

return Loop
