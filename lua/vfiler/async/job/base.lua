local JobBase = {}
JobBase.__index = JobBase

function JobBase.new(options)
  local self = setmetatable({
    _id = 0,
  }, JobBase)
  for key, value in pairs(options or {}) do
    self[key] = value
  end
  return self
end

function JobBase:start()
  if self.command and self._id <= 0 then
    self._id = self:_on_start()
  end
end

function JobBase:stop()
  if self._id > 0 then
    self:_on_stop()
    self._id = 0
  end
end

function JobBase:_on_start()
  assert(false, 'Not implemented.')
end

function JobBase:_on_stop()
  assert(false, 'Not implemented.')
end

function JobBase:_on_received(data)
  if self.on_received then
    self.on_received(self, data)
  end
end

function JobBase:_on_error(message)
  -- for debug
  --require('vfiler/core').message.error(message)
end

function JobBase:_on_completed()
  if self.on_completed then
    self.on_completed(self)
  end
  self:stop()
end

return JobBase
