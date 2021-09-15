local buffer = require 'vfiler/buffer'
local configs = require 'vfiler/configs'
local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local M = {}

function M.start_command(args)
  print(args)
  local configs = require"vfiler/configs".parse_command_args(args)
end

function M.start(configs)
  if configs.path == '' then
    configs.path = vim.fn.getcwd()
  end
  print(core.normalized_path(configs.path))
  buffer.create('test')
end

return M
