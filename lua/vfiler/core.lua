local M = {}
M.api = {}

if vim.fn.has('nvim') == 1 then
  M.api.command = vim.api.nvim_command
else
  M.api.command = vim.command
end

function M.warning(message)
  M.api.command(
    string.format('echohl WarningMsg | echo "%s" | echohl None', message)
  )
end

return M
