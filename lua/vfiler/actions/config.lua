local core = require('vfiler/libs/core')

local M = {}

-- Default configs
M.configs = {
  hook = {
    filter_choose_window = function(winids)
      return winids
    end,
    read_preview_file = function(path, default_read_func)
      return default_read_func(path)
    end,
  },
}

--- Setup vfiler configs
---@param configs table
function M.setup(configs)
  core.table.merge(M.configs, configs)
  return M.configs
end

return M
