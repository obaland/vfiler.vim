local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local M = {}

local extensions = {}

------------------------------------------------------------------------------
-- interfaces
------------------------------------------------------------------------------
function M.create(class, name, source_bufnr)
end

function M.delete(extension)
end

function M.get_extension()
  return extensions[vim.fn.bufnr()]
end

function M.register(ext)
  extensions[ext.number] = ext
end

function M.unregister(ext)
  extensions[ext.number] = nil
end

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
  extension.unregister(ext)
  ext:quit()
end

return M
