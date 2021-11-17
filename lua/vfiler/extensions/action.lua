local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Extension = require 'vfiler/extensions/extension'

local M = {}

------------------------------------------------------------------------------
-- interfaces
------------------------------------------------------------------------------
function M.do_action(name, ...)
  if not M[name] then
    core.message.error('Action "%s" is not defined.', name)
    return
  end

  local extension = Extension.get(vim.fn.bufnr())
  if not extension then
    core.message.error('Extension does not exist.')
    return
  end
  M[name](extension, ...)
end

------------------------------------------------------------------------------
-- actions
------------------------------------------------------------------------------
function M.delete(extension)
end

function M.loop_cursor_down(extension)
  local pos = vim.fn.line('.') + 1
  vim.fn.cursor(pos > vim.fn.line('$') and 1 or pos, 1)
end

function M.loop_cursor_up(extension)
  local pos = vim.fn.line('.') - 1
  vim.fn.cursor(pos < 1 and vim.fn.line('$') or pos, 1)
end

function M.move_cursor_down(extension)
  vim.fn.cursor(vim.fn.line('.') + 1, 1)
end

function M.move_cursor_up(extension)
  vim.fn.cursor(vim.fn.line('.') - 1, 1)
end

function M.quit(extension)
  extension:quit()
end

return M
