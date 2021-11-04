local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local M = {}

local keymappings = {}

function M._call(key, bufnr)
  local keymapping = keymappings[bufnr]
  if not keymapping then
    core.error('Not defined in the "%d" buffer', bufnr)
    return
  end

  local func = keymapping.mappings[key]
  if not keymapping then
    core.error('Not defined in the "%s" key', key)
    return
  end
  keymapping.do_action(bufnr, func)
end

function M.define(bufnr, mappings, func)
  keymappings[bufnr] = {
    mappings = core.deepcopy(mappings),
    do_action = func,
  }

  local options = {
    noremap = true,
    nowait = true,
    silent = true,
  }
  for key, _ in pairs(mappings) do
    local rhs = (
      [[lua: require('vfiler/mapping')._call('%s', %d)<CR>]]
      ):format(key, bufnr)
    vim.set_buf_keymap('n', key, rhs, options)
  end
end

function M.undefine(bufnr)
  keymappings[bufnr] = nil
end

return M
