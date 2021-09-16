local vim = require 'vfiler/vim'

local M = {}

M.is_windows = vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1

function M.escape_pettern(str)
  local escaped = str:gsub('([%.%^%$%*%+%-%?])', '%%%1')
  return escaped
end

function M.normalized_path(path)
  if path == '/' then
    return '/'
  end
  -- trim trailing path separator
  local result = vim.fn.fnamemodify(vim.fn.resolve(path), ':p')
  local len = result:len()

  if result:match('/$') or result:match('\\$') then
    result = result:sub(0, len - 1)
  end

  if M.is_windows then
    result = result:gsub('\\', '/')
  end

  return result
end

function M.warning(message)
  vim.command(
    string.format('echohl WarningMsg | echo "%s" | echohl None', message)
  )
end

return M
