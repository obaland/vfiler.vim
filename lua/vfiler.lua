local action = require('vfiler/action')
local config = require('vfiler/config')
local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local Context = require('vfiler/context')
local VFiler = require('vfiler/vfiler')

local M = {}

---Start vfiler from command line arguments
---@param args string: command line argumets
function M.start_command(args)
  local options, dirpath = config.parse_options(args)
  if not options then
    return false
  end
  return M.start(dirpath, { options = options })
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
  local merged_configs = core.table.copy(config.configs)
  core.table.merge(merged_configs, configs or {})

  VFiler.cleanup()

  local options = merged_configs.options
  local context = Context.new(merged_configs)
  local vfiler = VFiler.find_visible(options.name)
  if vfiler then
    vfiler:open()
    vfiler:update(context)
    vfiler:do_action(action.cd, dirpath)
    return true
  end

  local layout = options.layout
  if layout ~= 'none' then
    core.window.open(layout)
  end

  vfiler = VFiler.find_hidden(options.name)
  if options.new or not vfiler then
    vfiler = VFiler.new(context)
  else
    vfiler:open()
    vfiler:update(context)
  end

  vfiler:start(dirpath)
  return true
end

return M
