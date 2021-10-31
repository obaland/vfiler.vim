local M = {}

-- Alias
M.api = vim.api
M.command = vim.api.nvim_command
M.fn = vim.fn
M.o = vim.o

------------------------------------------------------------------------------
-- Global option
------------------------------------------------------------------------------
M.get_global_option_value = vim.api.nvim_get_option -- Alias
M.get_global_option_boolean = vim.api.nvim_get_option -- Alias
M.set_global_option = vim.api.nvim_set_option -- Alias

function M.get_option_value(name)
  return vim.o[name]
end
M.get_option_boolean = M.get_option_value -- Alias

function M.set_option(name, value)
  vim.o[name] = value
end

------------------------------------------------------------------------------
-- Buffer option
------------------------------------------------------------------------------
function M.get_buf_option_value(name, value)
  return vim.api.nvim_buf_get_option(0, name)
end
M.get_buf_option_boolean = M.get_buf_option_value -- Alias
function M.set_buf_option(name, value)
  vim.api.nvim_buf_set_option(0, name, value)
end

------------------------------------------------------------------------------
-- Window option
------------------------------------------------------------------------------
function M.get_win_option_value(name)
  return vim.api.nvim_win_get_option(0, name)
end
M.get_win_option_boolean = M.get_win_option_value -- Alias
function M.set_win_option(name, value)
  vim.api.nvim_win_set_option(0, name, value)
end

------------------------------------------------------------------------------
-- Key mapping
------------------------------------------------------------------------------
M.set_keymap = vim.api.nvim_set_keymap
function M.set_buf_keymap(mode, lhs, rhs, opts)
  vim.api.nvim_buf_set_keymap(0, mode, lhs, rhs, opts)
end

------------------------------------------------------------------------------
-- Lua data to Vim data
------------------------------------------------------------------------------
function M.vim_list(data)
  return data
end
function M.vim_dict(data)
  return data
end

return M
