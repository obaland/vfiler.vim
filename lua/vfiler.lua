local config = require 'vfiler/config'
local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Context = require 'vfiler/context'
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
  local path = vim.fn.fnamemodify(vfiler.context.root.path, ':~')
  return core.path.escape(path)
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
  local direction = options.direction

  local vfiler = nil
  if direction ~= 'none' then
    core.window.open(direction)
    vfiler = VFiler.find_hidden(options.name)
  else
    vfiler = VFiler.find(options.name)
  end

  local context = Context.new(configs)
  if options.new or not vfiler then
    vfiler = VFiler.new(context)
  else
    vfiler:open()
    vfiler:reset(context)
  end

  vfiler:start(dirpath)
  return true
end

return M
