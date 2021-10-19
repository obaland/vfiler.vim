local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Extension = require 'vfiler/extensions/extension'

local M = {}

------------------------------------------------------------------------------
-- interfaces
------------------------------------------------------------------------------
function M.do_action(name, ...)
  if not M[name] then
    core.error(string.format('Action "%s" is not defined', name))
    return
  end

  local extension = Extension.get(vim.fn.bufnr())
  if not extension then
    core.error('Extension does not exist.')
    return
  end
  M[name](extension, ...)
end

------------------------------------------------------------------------------
-- actions
------------------------------------------------------------------------------
function M.move_cursor_down(extension, loop)
  local pos = vim.fn.line('.') + 1
  if loop then
    pos = (pos > vim.fn.line('$')) and 1 or pos
  end
  vim.fn.cursor(pos, 1)
end

function M.move_cursor_up(extension, loop)
  local pos = vim.fn.line('.') - 1
  if loop then
    pos = (pos < 1) and vim.fn.line('$') or pos
  end
  vim.fn.cursor(pos, 1)
end

function M.quit(extension)
  extension:quit()
end

return M
