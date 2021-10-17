local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local M = {}

local keymapping_functions = {}

M.keymappings = {}

function M.define(type)
  local mappings = M.keymappings[type]
  if not mappings then
    return
  end
  keymapping_functions[type] = {}

  local options = {
    noremap = true,
    nowait = true,
    silent = true,
  }
  --[[
  for key, rhs in pairs(mappings) do
    vim.set_buf_keymap('n', key, rhs .. '<CR>', options)
  end
  ]]
  for key, rhs in pairs(mappings) do
    keymapping_functions[type][key] = rhs
    vim.set_buf_keymap('n', key,
      ([[:lua require('vfiler/mapping').execute('%s', '%s')<CR>]]):format(type, key),
      options
      )
  end
end

function M.execute(type, key)
  local func = keymapping_functions[type][key]
  if not func then
    core.error(([[Key "%s" is not mapping.]]):format(key))
    return
  end
  func()
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
