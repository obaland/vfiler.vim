local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local M = {}

local keymappings = {}

function M.define(type)
  local mappings = keymappings[type]
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
  if not keymappings[type] then
    keymappings[type] = {}
  end
  keymappings[type][key] = rhs
end

function M.setup(keymaps)
  core.merge_table(keymappings, keymaps)
end

return M
