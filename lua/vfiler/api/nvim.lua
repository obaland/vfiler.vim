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

function M.get_option_value(name)
  return vim.o[name]
end
M.get_option_boolean = M.get_option_value -- Alias

------------------------------------------------------------------------------
-- Buffer option
------------------------------------------------------------------------------
function M.get_buf_option_value(name, value)
  return vim.bo[name]
end
M.get_buf_option_boolean = M.get_buf_option_value -- Alias

------------------------------------------------------------------------------
-- Window option
------------------------------------------------------------------------------
function M.get_win_option_value(name)
  return vim.wo[name]
end
M.get_win_option_boolean = M.get_win_option_value -- Alias

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
function M.to_vimlist(data)
  return data
end
function M.to_vimdict(data)
  return data
end

------------------------------------------------------------------------------
-- Vim data to Lua data
------------------------------------------------------------------------------
function M.from_vimlist(data)
  return data
end
function M.from_vimdict(data)
  return data
end

return M
