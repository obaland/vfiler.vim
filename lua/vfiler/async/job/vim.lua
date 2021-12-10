local core = require('vfiler/core')

local Job = {}

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
  local Base = require('vfiler/async/job/base')
  return core.inherit(Job, Base, options)
end

function Job:_on_start()
  -- assgin and update id
  local id = latest_id
  latest_id = math.min(latest_id + 1, math.maxinteger)
  jobs[id] = self
  vim.fn['vfiler#job#start'](id, self.command)
  return id
end

function Job:_on_stop()
  vim.fn['vfiler#job#stop'](self._id)
  jobs[self._id] = nil
end

return Job
