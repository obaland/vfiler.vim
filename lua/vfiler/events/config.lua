local core = require('vfiler/libs/core')
local git = require('vfiler/events/git')

local M = {}

-- Default vfiler global event configs
M.configs = {
  enabled = true,
  events = {
    vfiler = {
      {
        event = { 'BufWritePost' },
        callback = git.update_file,
      },
    },
  },
}

--- Setup vfiler global events.
---@param configs table
function M.setup(configs)
  core.table.merge(M.configs, configs)
  return M.configs
end

return M
