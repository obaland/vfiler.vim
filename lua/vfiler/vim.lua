local M = nil

if vim.fn.has('nvim') == 1 then
  M = require 'vfiler/api/nvim'
else
  M = require 'vfiler/api/vim'
end

------------------------------------------------------------------------------
-- Set options
------------------------------------------------------------------------------
local function set_option_command(command, name, value)
  local option = ''
  if type(value) == 'boolean' then
    option = value and name or 'no' .. name
  else
    option = ('%s=%s'):format(name, M.fn.escape(value, ' '))
  end
  return command .. ' ' .. option
end

function M.set_global_option_command(name, value)
  return set_option_command('setglobal', name, value)
end

function M.set_option_command(name, value)
  return set_option_command('set', name, value)
end

function M.set_local_option_command(name, value)
  return set_option_command('setlocal', name, value)
end

function M.set_global_option(name, value)
  M.command(M.set_global_option_command(name, value))
end

function M.set_option(name, value)
  M.command(M.set_option_command(name, value))
end

function M.set_local_option(name, value)
  M.command(M.set_local_option_command(name, value))
end

function M.set_global_option_commands(options)
  local commands = {}
  for key, value in pairs(options) do
    table.insert(commands, M.set_global_option_command(key, value))
  end
  return commands
end

function M.set_option_commands(options)
  local commands = {}
  for key, value in pairs(options) do
    table.insert(commands, M.set_option_command(key, value))
  end
  return commands
end

function M.set_local_option_commands(options)
  local commands = {}
  for key, value in pairs(options) do
    table.insert(commands, M.set_local_option_command(key, value))
  end
  return commands
end

function M.set_global_options(options)
  M.commands(M.set_global_option_commands(options))
end

function M.set_options(options)
  M.commands(M.set_option_commands(options))
end

function M.set_local_options(options)
  M.commands(M.set_local_option_commands(options))
end

function M.commands(cmds)
  M.command(table.concat(cmds, ' | '))
end

function M.fn.win_executes(window, cmds)
  M.fn.win_execute(window, table.concat(cmds, ' | '))
end

return M
