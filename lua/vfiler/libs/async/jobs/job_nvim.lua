local Job = {}
Job.__index = Job

local function on_error(job, message)
  -- for debug
  error(message)
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
  local jobopts = {
    on_stderr = function(channel, datas, name)
      local message = table.concat(datas)
      if #message > 0 then
        on_error(self, message)
      end
    end,
  }
  local data_buffer = ''
  if options.on_received then
    jobopts.on_stdout = function(channel, datas, name)
      datas[1] = data_buffer .. datas[1]
      local data_len = #datas
      if datas[data_len] ~= '' then
        data_buffer = datas[data_len]
        data_len = data_len - 1
      else
        data_buffer = ''
      end
      for i = 1, data_len do
        local data = datas[i]
        if #data > 0 then
          options.on_received(self, data)
        end
      end
    end
  end
  if options.on_completed then
    jobopts.on_exit = function(id, code, event)
      if options.on_received and data_buffer ~= '' then
        options.on_received(self, data_buffer)
      end
      options.on_completed(self, code)
    end
  end
  self._id = vim.fn.jobstart(command, jobopts)
end

function Job:stop()
  if self._id ~= 0 then
    vim.fn.jobstop(self._id)
    self._id = 0
  end
end

function Job:wait(timeout)
  if self._id ~= 0 then
    timeout = timeout or -1
    vim.fn.jobwait({ self._id }, timeout)
  end
end

return Job
