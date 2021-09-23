local vim = require 'vfiler/vim'

local M = {}

local mappings = {}

function M.define()
  local opts = {
    noremap = true,
    nowait = true,
    silent = true,
  }

  for key, rhs in pairs(mappings) do
    vim.set_buf_keymap('n', key, rhs, opts)
  end
end

function M.set(key, rhs)
  mappings[key] = rhs
end

function M.setup(maps)
  mappings = maps
end

return M
