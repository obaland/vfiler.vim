local Job = {}
Job.__index = Job

local MAX_JOBID = 65535
local latest_job_id = 1
local jobs = {}

local job_start = vim.fn['vfiler#job#start']
local job_stop = vim.fn['vfiler#job#stop']
local job_wait = vim.fn['vfiler#job#wait']

function Job._on_error(id, message)
  error(message)
end

function Job._on_received(id, message)
  local job = jobs[id]
  if not (job and job._on_received) then
    return
  end
  job._on_received(job, message)
end

function Job._on_completed(id, code)
  local job = jobs[id]
  if not (job and job._on_completed) then
    return
  end
  job._on_completed(job, code)
  -- auto job stop
  job:stop()
end

function Job.new()
  return setmetatable({
    _id = 0,
  }, Job)
end

function Job:start(command, options)
  if self._id ~= 0 then
    return
  end

  self._id = latest_job_id
  latest_job_id = latest_job_id + 1
  if latest_job_id > MAX_JOBID then
    latest_job_id = 1
  end
  assert(jobs[self._id] == nil)
  jobs[self._id] = self

  if options.on_received then
    self._on_received = options.on_received
  end
  if options.on_completed then
    self._on_completed = options.on_completed
  end
  job_start(self._id, command)
end

function Job:stop()
  if self._id ~= 0 then
    job_stop(self._id)
    jobs[self._id] = nil
    self._id = 0
  end
end

function Job:wait(timeout)
  if self._id ~= 0 then
    timeout = timeout or -1
    job_wait(self._id, timeout, vim.fn.reltime())
  end
end

return Job
