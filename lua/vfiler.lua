local action = require 'vfiler/action'
local config = require 'vfiler/config'
local core = require 'vfiler/core'
local repository = require 'vfiler/repository'
local vim = require 'vfiler/vim'

local M = {}

function M.parse_command_args(args)
  return vim.convert_table(config.parse(args))
end

function M.start_command(args)
  local configs = config.parse(args)
  if not configs then
    return false
  end
  return M.start(configs)
end

function M.start(configs)
  if configs.path == '' then
    configs.path = vim.fn.getcwd()
  end
  configs.path = core.normalized_path(configs.path)

  configs.name = 'test'

  local source = repository.get(configs.name)
  if source then
    -- TODO: open action
  end
  local buffer = repository.create(configs)
  action.do_action('start', buffer.context, buffer.view, configs.path)
  return true
end

return M
