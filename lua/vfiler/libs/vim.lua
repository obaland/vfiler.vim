local M
if vim.fn.has('nvim') == 1 then
  M = require('vfiler/libs/api/nvim')
else
  M = require('vfiler/libs/api/vim')
end

------------------------------------------------------------------------------
-- Set options
------------------------------------------------------------------------------

function M.get_buf_option(buffer, name)
  return M.fn.getbufvar(buffer, '&' .. name)
end
function M.get_buf_option_boolean(buffer, name)
  return M.get_buf_option(buffer, name) == 1
end
function M.get_win_option(window, name)
  return M.fn.getwinvar(window, '&' .. name)
end
function M.get_win_option_boolean(window, name)
  return M.fn.get_win_option(window, name) == 1
end

local function set_option_command(command, name, value)
  local option
  if type(value) == 'boolean' then
    option = value and name or 'no' .. name
  else
    option = ('%s=%s'):format(name, M.fn.escape(value, ' '))
  end
  return command .. ' ' .. option
end

function M.set_option(name, value)
  M.command(set_option_command('set', name, value))
end
function M.set_global_option(name, value)
  M.command(set_option_command('setglobal', name, value))
end
function M.set_buf_option(buffer, name, value)
  if type(value) == 'boolean' then
    value = value and 1 or 0
  end
  M.fn.setbufvar(buffer, '&' .. name, value)
end
function M.set_win_option(window, name, value)
  if type(value) == 'boolean' then
    value = value and 1 or 0
  end
  M.fn.setwinvar(window, '&' .. name, value)
end

function M.set_global_options(options)
  for name, value in pairs(options) do
    M.set_global_option(name, value)
  end
end
function M.set_options(options)
  for name, value in pairs(options) do
    M.set_option(name, value)
  end
end
function M.set_buf_options(buffer, options)
  for name, value in pairs(options) do
    M.set_buf_option(buffer, name, value)
  end
end
function M.set_win_options(window, options)
  for name, value in pairs(options) do
    M.set_win_option(window, name, value)
  end
end

------------------------------------------------------------------------------
-- Utilities
------------------------------------------------------------------------------

function M.commands(cmds)
  M.command(table.concat(cmds, ' | '))
end

function M.win_executes(window, cmds)
  for _, cmd in ipairs(cmds) do
    M.fn.win_execute(window, cmd)
  end
end

return M
