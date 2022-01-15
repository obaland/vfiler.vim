local core = require('vfiler/libs/core')

-- Vim functions
local job_start = vim.fn['vfiler#async#job_start']
local job_stop = vim.fn['vfiler#async#job_stop']

local Job = {}

local MAX_ID = 65535
local latest_id = 1
local jobs = {}

function Job._out_cb(id, message)
  local job = jobs[id]
  if not job then
    return
  end
  job:_on_received(message)
end

function Job._err_cb(id, message)
  local job = jobs[id]
  if not job then
    return
  end
  job:_on_error(message)
end

function Job._close_cb(id)
  local job = jobs[id]
  if not job then
    return
  end
  job:_on_completed()
end

function Job.new(options)
  local Base = require('vfiler/libs/async/job/base')
  return core.inherit(Job, Base, options)
end

function Job:_on_start()
  -- assgin and update id
  local id = latest_id
  latest_id = latest_id + 1
  if latest_id > MAX_ID then
    latest_id = 1
  end
  jobs[id] = self
  job_start(id, self.command)
  return id
end

function Job:_on_stop()
  job_stop(self._id)
  jobs[self._id] = nil
end

return Job
