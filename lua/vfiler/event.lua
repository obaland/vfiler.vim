local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local registered_events = {}

local Event = {}
Event.__index = Event

function Event.new(config)
  local self = setmetatable({
    _bufnr = config.bufnr,
    _callback = config.callback,
    _args = config.args,
    _event_actions = {},
  }, Event)
  self:_register(config.events)
  return self
end

function Event._handle(bufnr, group, event)
  local e = registered_events[bufnr]
  if not e then
    return
  end
  e:handle(group, event)
end

function Event:handle(group, event)
  local events = self._event_actions[group]
  if not events then
    core.message.error('Event group "%s" is not registered.', group)
    return
  end

  local actions = events[event]
  if not actions then
    core.message.error('Event "%s" is not registered.', event)
    return
  end

  for _, action in ipairs(actions) do
    self._callback(action, self._args)
  end
end

function Event:unregister()
  local bufnr = self._bufnr
  if bufnr <= 0 then
    return
  end

  for group, _ in pairs(self._event_actions) do
    core.autocmd.delete_group(group)
  end

  if registered_events[bufnr] then
    registered_events[bufnr] = nil
  end
  self._bufnr = -1
end

function Event:_register(events)
  for group, eventlist in pairs(events) do
    local commands = { core.autocmd.start_group(group) }
    local actions = {}
    local function register(event, action)
      if not actions[event] then
        actions[event] = {}
      end
      table.insert(actions[event], action)

      local cmd = (':lua require("vfiler/event")._handle(%d, "%s", "%s")'):format(
        self._bufnr,
        group,
        event
      )
      table.insert(commands, core.autocmd.create(event, cmd, { buffer = 0 }))
    end

    for i, event in ipairs(eventlist) do
      if type(event.event) == 'string' then
        register(event.event, event.action)
      elseif type(event.event) == 'table' then
        for _, e in ipairs(event.event) do
          register(e, event.action)
        end
      else
        core.message.error(
          'Invalid event has been set for group "%s". (%d)',
          group,
          i
        )
      end
    end
    self._event_actions[group] = actions
    table.insert(commands, core.autocmd.end_group())
    vim.commands(commands)
  end
  registered_events[self._bufnr] = self
end

return Event
