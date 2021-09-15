local M = {}

M.fn = vim.fn
if vim.fn.has('nvim') == 1 then
  M.command = vim.api.nvim_command
else
  M.command = vim.command
end

return M
