local configs = require 'vfiler/configs'
local core = require 'vfiler/core'

local M = {}

function M.start_command(args)
  print(args)
  local configs = require"vfiler/configs".parse_command_args(args)
end

function M.start(configs)
  if configs.path == '' then
    configs.path = core.fn.getcwd()
  end
  print(core.normalized_path(configs.path))
end

return M
