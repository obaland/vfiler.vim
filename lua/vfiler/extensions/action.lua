local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local M = {}

------------------------------------------------------------------------------
-- interfaces
------------------------------------------------------------------------------
function M.do_action(name)
  if not M[name] then
    core.error(string.format('Action "%s" is not defined', name))
    return
  end

  local extension = M.extensions[vim.fn.bufnr()]
  if not extension then
    core.error('Extension does not exist.')
    return
  end
  M[name](extension)
end

------------------------------------------------------------------------------
-- actions
------------------------------------------------------------------------------
function M.quit(extension)
  extension:delete()
end

return M
