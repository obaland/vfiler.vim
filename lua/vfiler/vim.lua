local M = nil

if vim.fn.has('nvim') == 1 then
  M = require 'vfiler/api/nvim'
else
  M = require 'vfiler/api/vim'
end

------------------------------------------------------------------------------
-- Set options
------------------------------------------------------------------------------

function M.get_buf_option(buffer, name)
  return vim.fn.getbufvar(buffer, '&' .. name)
end
function M.get_buf_option_boolean(buffer, name)
  return M.get_buf_option(buffer, name) == 1
end
function M.get_win_option(window, name)
  return vim.fn.getwinvar(window, '&' .. name)
end
function M.get_win_option_boolean(window, name)
  return vim.fn.get_win_option(window, name) == 1
end

function M.set_option(name, value)
  set_option_command('set', name, value)
end
function M.set_global_option(name, value)
  set_option_command('setglobal', name, value)
end
function M.set_buf_option(buffer, name, value)
  vim.fn.setbufvar(buffer, '&' .. name, value)
end
function M.set_win_option(window, name, value)
  vim.fn.setwinvar(window, '&' .. name, value)
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

function M.fn.win_executes(window, cmds)
  M.fn.win_execute(window, table.concat(cmds, ' | '))
end

return M
