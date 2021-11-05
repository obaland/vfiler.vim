local vim = require 'vfiler/vim'

local M = {}

local function tocode(key)
  local capture = key:match('^<(.+)>$')
  if capture then
    return '[' .. capture .. ']'
  end
  return key
end

function M.define(bufnr, mappings, funcstr)
  local options = {
    noremap = true,
    nowait = true,
    silent = true,
  }

  local keymaps = {}
  for key, func in pairs(mappings) do
    local code = tocode(key)
    local rhs = ([[:lua %s(%d, '%s')<CR>]]):format(funcstr, bufnr, code)

    keymaps[code] = func
    vim.set_buf_keymap('n', key, rhs, options)
  end
  return keymaps
end

return M
