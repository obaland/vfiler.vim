local core = require 'vfiler/core'

local M = {}

M.configs = {}

function M.setup(configs)
  return core.table.merge(M.configs, configs)
end

return M
