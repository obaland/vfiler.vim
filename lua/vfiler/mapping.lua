local vim = require('vfiler/libs/vim')

local M = {}

local function escape_key(key)
  local capture = key:match('^<(.+)>$')
  if capture then
    key = '[' .. capture .. ']'
  end
  return key
end

function M.define(bufnr, mappings, funcstr)
  if not mappings then
    return {}
  end

  local options = {
    noremap = true,
    nowait = true,
    silent = true,
  }

  local keymaps = {}
  for key, func in pairs(mappings) do
    local escaped = escape_key(key)
    local rhs = ([[:lua %s(%d, '%s')<CR>]]):format(
      funcstr,
      bufnr,
      vim.fn.escape(escaped, '\\')
    )

    keymaps[escaped] = func
    vim.set_buf_keymap('n', key, rhs, options)
  end
  return keymaps
end

function M.undefine(mappings)
  for key, _ in pairs(mappings) do
    vim.del_buf_keymap('n', key)
  end
end

return M
