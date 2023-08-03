local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local registered_events = {}

local function get_group_name(group, bufnr)
  return (bufnr > 0) and (group .. '_' .. bufnr) or group
end

local M = {}

function M._handle(bufnr, group, event)
  local registered = registered_events[bufnr]
  if not registered then
    return
  end
  local events = registered[group]
  if not events then
    return
  end
  local callbacks = events[event]
  if not callbacks then
    return
  end
  if bufnr == 0 then
    -- NOTE: Convert to integer type.
    bufnr = vim.fn.expand('<abuf>') + 0
  end
  for _, callback in ipairs(callbacks) do
    callback(bufnr, group, event)
  end
end

function M.register(group, events, bufnr)
  bufnr = bufnr or 0
  local group_name = get_group_name(group, bufnr)

  -- Delete previously registered events, and re-register.
  core.autocmd.delete_group(group_name)

  local commands = { core.autocmd.start_group(group_name) }
  local this_module = 'require("vfiler/events/event")'
  local callbacks = {}
  local options = {}
  if bufnr > 0 then
    options.buffer = bufnr
  end

  local function register(event, callback)
    if not callbacks[event] then
      callbacks[event] = {}
    end
    table.insert(callbacks[event], callback)

    local method = ('_handle(%d, "%s", "%s")'):format(bufnr, group, event)
    local cmd = (':lua %s.%s'):format(this_module, method)
    table.insert(commands, core.autocmd.create(event, cmd, options))
  end

  if not registered_events[bufnr] then
    registered_events[bufnr] = {}
  end
  local registered = registered_events[bufnr]

  for _, event in ipairs(events) do
    local type = type(event.event)
    if type == 'string' then
      register(event.event, event.callback)
    elseif type == 'table' then
      for _, e in ipairs(event.event) do
        register(e, event.callback)
      end
    else
      core.message.error('Invalid event for group "%s".', group)
    end
  end
  registered[group] = callbacks
  table.insert(commands, core.autocmd.end_group())
  vim.commands(commands)
end

function M.unregister(group, bufnr)
  bufnr = bufnr or 0
  local group_name = get_group_name(group, bufnr)
  core.autocmd.delete_group(group_name)
  local registered = registered_events[bufnr]
  if registered then
    registered[group] = nil
  end
end

function M.clear(bufnr)
  local registered = registered_events[bufnr]
  if not registered then
    return
  end
  for group, _ in pairs(registered) do
    core.autocmd.delete_group(get_group_name(group, bufnr))
  end
  registered_events[bufnr] = nil
end

return M
