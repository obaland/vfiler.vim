local core = require('vfiler/core')

local function for_each(jobs, func)
  for _, job in ipairs(jobs) do
    func(job)
  end
end

local JobBase = {}
JobBase.__index = JobBase

function JobBase.new(options)
  local self = setmetatable({
    auto_stop = true,
    canceled = false,
    _id = 0,
    _chains = {},
    _canceled_count = 0,
    _completed_count = 0,
    _target_jobs = 0,
  }, JobBase)
  for key, value in pairs(options) do
    self[key] = value
  end
  return self
end

function JobBase:cancel()
  if self._id > 0 then
    self.canceled = true
    self:stop()
    self:_on_canceled()
  end
  for_each(self._chains, JobBase.cancel)
end

function JobBase:chain(job)
  -- hook callbacks
  local on_completed = job.on_completed
  job.on_completed = function(j)
    self._completed_count = self._completed_count + 1
    on_completed(j)
  end

  local on_canceled = job.on_canceled
  job.on_canceled = function(j)
    self._canceled_count = self._canceled_count + 1
    on_canceled(j)
  end

  table.insert(self._chains, job)
end

function JobBase:start()
  if self.command and self._id <= 0 then
    self._canceled_count = 0
    self._completed_count = 0
    self.canceled = false
    self._id = self:_on_start()
  end
  for_each(self._chains, JobBase.start)
end

function JobBase:stop()
  if self._id > 0 then
    self:_on_stop()
    self._id = 0
  end
  for_each(self._chains, JobBase.stop)
end

function JobBase:_on_cancel()
  assert(false, 'Not implemented.')
end

function JobBase:_on_start()
  assert(false, 'Not implemented.')
end

function JobBase:_on_stop()
  assert(false, 'Not implemented.')
end

function JobBase:_on_canceled()
  if self._canceled_count ~= #self._chains then
    return
  end

  if self.on_canceled then
    self.on_canceled(self)
  end
end

function JobBase:_on_received(data)
  if self.on_received then
    self.on_received(self, data)
  end
end

function JobBase:_on_error(message)
  -- for debug
  --core.message.error(message)
end

function JobBase:_on_completed()
  if self.canceled then
    return
  end

  if self._completed_count ~= #self._chains then
    return
  end

  if self.on_completed then
    self.on_completed(self)
  end
  if self.auto_stop then
    self:stop()
  end
end

return JobBase
