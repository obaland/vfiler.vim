local Buffer = require 'vfiler/buffer'
local config = require 'vfiler/config'
local core = require 'vfiler/core'
local repository = require 'vfiler/repository'
local vim = require 'vfiler/vim'

local M = {}

function M.parse_command_args(args)
  return config.parse(args)
end

function M.start_command(args)
  local configs = M.parse_command_args(args)
  if not configs then
    return
  end
  M.start(configs)
end

function M.start(configs)
  if configs.path == '' then
    configs.path = vim.fn.getcwd()
  end
  configs.path = core.normalized_path(configs.path)

  configs.name = 'test'

  local source = repository.get(configs.name)
  if not source then
    local source = repository.create(configs)
  end
  -- TODO: do action
end

return M
