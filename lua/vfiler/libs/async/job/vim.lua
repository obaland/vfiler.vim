local core = require('vfiler/libs/core')

-- Vim functions
local job_start = vim.fn['vfiler#async#job_start']
local job_stop = vim.fn['vfiler#async#job_stop']

local Job = {}

local MAX_ID = 65535
local latest_id = 1

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

  local options = vim.dict({
    out_cb = function(channel, message)
      self:_on_received(message)
    end,

    err_cb = function(channel, message)
      self:_on_error(message)
    end,

    close_cb = function(channel)
      self:_on_completed()
    end,
  })
  job_start(id, self.command, options)
  return id
end

function Job:_on_stop()
  job_stop(self._id)
end

return Job
