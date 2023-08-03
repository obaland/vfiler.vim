local config = require('vfiler/events/config')
local event = require('vfiler/events/event')

local M = {}

function M.setup(configs)
  config.setup(configs)
end

function M.start()
  local configs = config.configs
  if not configs.enabled then
    event.clear(0)
    return
  end
  for group, events in pairs(configs.events) do
    event.register(group, events, 0)
  end
end

return M
