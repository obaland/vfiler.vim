local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Extension = require 'vfiler/extensions/extension'

local M = {}

------------------------------------------------------------------------------
-- interfaces
------------------------------------------------------------------------------
function M.do_action(name, ...)
  print('come')
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
  print(loop)
  local winid = extension.winid
  local pos = vim.fn.win_execute(winid, [[line('.')]])
  --vim.fn.win_execute(extension.winid, 'call cursor(
end

function M.quit(extension)
  extension:quit()
end

return M
