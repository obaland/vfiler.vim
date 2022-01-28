local core = require('vfiler/libs/core')

local M = {}

local function on_error(message)
  -- for debug
  core.message.error(message)
end

if core.is_nvim then
  function M.start(command, options)
    local jobopts = {
      on_stderr = function(channel, datas, name)
        local message = table.concat(datas)
        if #message > 0 then
          on_error(message)
        end
      end,
    }
    if options.on_received then
      jobopts.on_stdout = function(channel, datas, name)
        for _, data in ipairs(datas) do
          --local trimed = vim.trim(data)
          --if #trimed > 0 then
          --  self:_on_received(trimed)
          --end
          if #data > 0 then
            options.on_received(data)
          end
        end
      end
    end
    if options.on_completed then
      jobopts.on_exit = function(id, code, event)
        options.on_completed()
      end
    end
    vim.fn.jobstart(command, jobopts)
  end
else
  function M.start(command, options)
    local jobopts = vim.dict({
      err_cb = on_error,
    })
    if options.on_received then
      jobopts.out_cb = function(channel, message)
        options.on_received(message)
      end
    end

    if options.on_completed then
      jobopts.close_cb = function(channel)
        options.on_completed()
      end
    end
    vim.fn.job_start(command, jobopts)
  end
end

return M
