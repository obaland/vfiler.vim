local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local Extension = require('vfiler/extensions/extension')

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

function M.loop_cursor_down(extension)
  local pos = vim.fn.line('.') + 1
  if pos > extension:num_lines() then
    pos = 1
  end
  core.cursor.winmove(extension:winid(), pos)
end

function M.loop_cursor_up(extension)
  local pos = vim.fn.line('.') - 1
  if pos < 1 then
    pos = extension:num_lines()
  end
  core.cursor.winmove(extension:winid(), pos)
end

function M.move_cursor_down(extension)
  core.cursor.winmove(extension:winid(), vim.fn.line('.') + 1)
end

function M.move_cursor_up(extension)
  core.cursor.winmove(extension:winid(), vim.fn.line('.') - 1)
end

function M.quit(extension)
  extension:quit()
end

return M
