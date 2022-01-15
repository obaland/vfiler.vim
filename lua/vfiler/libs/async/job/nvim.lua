local core = require('vfiler/libs/core')

local Job = {}

function Job.new(options)
  local Base = require('vfiler/libs/async/job/base')
  return core.inherit(Job, Base, options)
end

function Job:_on_start()
  return vim.fn.jobstart(self.command, {
    on_stdout = function(channel, datas, name)
      for _, data in ipairs(datas) do
        --local trimed = vim.trim(data)
        --if #trimed > 0 then
        --  self:_on_received(trimed)
        --end
        if #data > 0 then
          self:_on_received(data)
        end
      end
    end,

    on_stderr = function(channel, datas, name)
      local message = table.concat(datas)
      if #message > 0 then
        self:_on_error(message)
      end
    end,

    on_exit = function(id, code, event)
      self:_on_completed()
    end,
  })
end

function Job:_on_stop()
  vim.fn.jobstop(self._id)
end

return Job
