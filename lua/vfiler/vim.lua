local M = nil

if vim.fn.has('nvim') == 1 then
  M = require 'vfiler/api/nvim'
else
  M = require 'vfiler/api/vim'
end

------------------------------------------------------------------------------
-- Utilities
------------------------------------------------------------------------------

function M.commands(cmds)
  M.command(table.concat(cmds, ' | '))
end

function M.set_options(options)
  for key, value in pairs(options) do
    M.set_option(key, value)
  end
end

function M.set_buf_options(options)
  for key, value in pairs(options) do
    M.set_buf_option(key, value)
  end
end

function M.command_set_option(command, name, value)
  local option = ''
  if type(value) == 'boolean' then
    option = value and name or 'no' .. name
  else
    option = ('%s=%s'):format(name, M.fn.escape(value, ' '))
  end
  return command .. ' ' .. option
end

function M.set_win_options(options)
  for key, value in pairs(options) do
    M.set_win_option(key, value)
  end
end

function M.fn.win_executes(window, cmds)
  M.fn.win_execute(window, table.concat(cmds, ' | '))
end

return M
