local config = require 'vfiler/config'
local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local VFiler = require 'vfiler/vfiler'

local M = {}

function M.complete(arglead)
  return config.complete(arglead)
end

function M.get_status_string()
  local vfiler = VFiler.get_current()
  if not (vfiler and vfiler.context.root) then
    return ''
  end
  return vfiler.context.root.path
end

function M.start_command(args)
  local options, dirpath = config.parse_options(args)
  if not options then
    return false
  end
  return M.start(dirpath, {options = options})
end

function M.start(...)
  local args = {...}
  local configs = core.table.copy(config.configs)
  core.table.merge(configs, args[2] or {})

  local dirpath = args[1]
  if not dirpath or dirpath == '' then
    dirpath = vim.fn.getcwd()
  end

  VFiler.cleanup()

  local options = configs.options
  local split = options.split

  local vfiler = nil
  if split ~= 'none' then
    -- split window
    local direction
    if split == 'horizontal' then
      direction = 'bottom'
    elseif split == 'vertical' then
      direction = 'left'
    elseif split == 'tab' then
      direction = 'tab'
    else
      core.message.error('Illegal "%s" split option.', split)
      return false
    end
    core.window.open(direction)
    vfiler = VFiler.find_hidden(options.name)
  else
    vfiler = VFiler.find(options.name)
  end

  if options.new or not vfiler then
    vfiler = VFiler.new(configs)
  else
    vfiler:open()
    vfiler:reset(configs)
  end

  vfiler:start(dirpath)
  return true
end

return M
