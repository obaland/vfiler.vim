local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local M = {}

M.configs = {
  layout = {
    --top = 'auto',
    floating = 'auto',
  },
}

function M.setup(configs)
  return core.merge_table(M.configs, configs)
end

return M
