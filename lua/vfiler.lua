local config = require('vfiler/config')
local core = require('vfiler/core')
local vim = require('vfiler/vim')

local Context = require('vfiler/context')
local VFiler = require('vfiler/vfiler')

local M = {}

---Get complete item list for command
---@param arglead string
---@return table: complete item list
function M.complete(arglead)
  return config.complete(arglead)
end

---Get status string for "statusline"
---@return string: status string
function M.get_status_string()
  local vfiler = VFiler.get_current()
  if not vfiler then
    return ''
  end
  return vfiler:get_status()
end

---Start vfiler from command line arguments
---@param args string: command line argumets
function M.start_command(args)
  local options, dirpath = config.parse_options(args)
  if not options then
    return false
  end
  return M.start(dirpath, {options = options})
end

---Start vfiler
function M.start(...)
  local args = {...}
  local dirpath = args[1]
  if not dirpath or dirpath == '' then
    dirpath = vim.fn.getcwd()
  end

  local configs = core.table.copy(config.configs)
  core.table.merge(configs, args[2] or {})

  VFiler.cleanup()

  local options = configs.options
  local layout = options.layout

  local vfiler = nil
  if layout ~= 'none' then
    core.window.open(layout)
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
