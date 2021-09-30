local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local M = {}

local mappings = {}

function M.define(name)
  local mapset = mappings[name]
  if not mapset then
    return
  end

  local options = {
    noremap = true,
    nowait = true,
    silent = true,
  }
  for key, rhs in pairs(mapset) do
    vim.set_buf_keymap('n', key, rhs, options)
  end
end

function M.set(name, key, rhs)
  mappings[name][key] = rhs
end

function M.setup(maps)
  for name, mapset in pairs(maps) do
    if not mappings[name] then
      mappings[name] = {}
    end
    local dest = mappings[name]
    core.merge(dest, mapset)
  end
end

return M
