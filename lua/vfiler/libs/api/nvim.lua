local M = {}

-- Alias
M.api = vim.api
M.command = vim.api.nvim_command
M.fn = vim.fn
M.eval = vim.api.nvim_eval
M.o = vim.o

------------------------------------------------------------------------------
-- Options
------------------------------------------------------------------------------
M.get_global_option = vim.api.nvim_get_option -- Alias
M.get_global_option_boolean = vim.api.nvim_get_option -- Alias

function M.get_option(name)
  return vim.o[name]
end
M.get_option_boolean = M.get_option -- Alias

------------------------------------------------------------------------------
-- Key mapping
------------------------------------------------------------------------------
M.set_keymap = vim.api.nvim_set_keymap
function M.set_buf_keymap(buffer, mode, lhs, rhs, opts)
  -- match behavior with vim
  assert(vim.fn.bufwinid(buffer) >= 0)
  vim.api.nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
end

M.del_keymap = vim.api.nvim_del_keymap
function M.del_buf_keymap(buffer, mode, lhs)
  -- match behavior with vim
  assert(vim.fn.bufwinid(buffer) >= 0)
  vim.api.nvim_buf_del_keymap(buffer, mode, lhs)
end

------------------------------------------------------------------------------
-- Lua data to Vim data
------------------------------------------------------------------------------
function M.to_vimlist(data)
  return data or {}
end
function M.to_vimdict(data)
  return data or {}
end

------------------------------------------------------------------------------
-- Vim data to Lua data
------------------------------------------------------------------------------
function M.from_vimlist(data)
  return data or {}
end
function M.from_vimdict(data)
  return data or {}
end

return M
