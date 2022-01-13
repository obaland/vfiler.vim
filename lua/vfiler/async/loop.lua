local Timer = require('vfiler/async/timer')

local M = {}

function M.run(callback)
  local timer = Timer.new({
    interval = 0,
    callback = function(t)
      if callback() then
        t:stop()
      end
    end,
  })
  timer:start()
end

return M
