local vim = require 'vfiler/vim'

local M = {}

local extensions = {}

local function getext()
  return extensions[vim.fn.bufnr()]
end

function M.do_action(name)
end

function M.register(ext)
  extensions[ext.number] = ext
end

function M.unregister(ext)
  extensions[ext.number] = nil
end

function M.quit()
  local ext = getext()
  M.unregister(ext)
  ext:quit()
end

return M
