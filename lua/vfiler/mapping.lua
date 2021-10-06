local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local M = {}

M.keymappings = {}

function M.define(type)
  local mappings = M.keymappings[type]
  if not mappings then
    return
  end

  local options = {
    noremap = true,
    nowait = true,
    silent = true,
  }
  for key, rhs in pairs(mappings) do
    vim.set_buf_keymap('n', key, rhs, options)
  end
end

function M.set(type, key, rhs)
  if not M.keymappings[type] then
    M.keymappings[type] = {}
  end
  M.keymappings[type][key] = rhs
end

function M.setup(keymaps)
  core.merge_table(M.keymappings, keymaps)
end

return M
