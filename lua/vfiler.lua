local configs = require 'vfiler/configs'

local M = {}

function M.start_command(args)
  print(args)
  local configs = require"vfiler/configs".parse_command_args(args)
end

function M.start(options)
end

return M
