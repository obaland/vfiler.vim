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
function M.start(dirpath, configs)
  if not dirpath or #dirpath <= 0 then
    dirpath = vim.fn.getcwd()
  end
  dirpath = vim.fn.fnamemodify(dirpath, ':p')
  if vim.fn.isdirectory(dirpath) ~= 1 then
    core.message.error('Does not exist "%s".', dirpath)
    return false
  end
  local combined_configs = core.table.copy(config.configs)
  core.table.merge(combined_configs, configs or {})

  VFiler.cleanup()

  local options = combined_configs.options
  local layout = options.layout

  local vfiler = nil
  if layout ~= 'none' then
    core.window.open(layout)
    vfiler = VFiler.find_hidden(options.name)
  else
    vfiler = VFiler.find(options.name)
  end

  local context = Context.new(combined_configs)
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
