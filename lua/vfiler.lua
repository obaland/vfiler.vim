local action = require 'vfiler/action'
local config = require 'vfiler/config'
local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local Buffer = require 'vfiler/buffer'

local M = {}

local function _action(name, ...)
  local func = [[:lua require('vfiler/action').do_action]]
  if ... then
    func = func .. ([[('%s', %s)]]):format(name, ...)
  else
    func = func .. ([[('%s')]]):format(name)
  end
  return func
end

mapping.setup {
  main = {
    ['<CR>']  = _action('open'),
    ['<Tab>'] = _action('switch_to_buffer'),
    ['gg']    = _action('move_cursor_top'),
    ['h']     = _action('close_tree_or_cd'),
    ['j']     = _action('move_cursor_down', 'true'),
    ['k']     = _action('move_cursor_up', 'true'),
    ['l']     = _action('open_tree'),
    ['q']     = _action('quit'),
    ['G']     = _action('move_cursor_bottom'),
    ['L']     = _action('change_drive'),
    ['S']     = _action('change_sort'),
  },
}

function M.parse_command_args(args)
  return vim.to_vimdict(config.parse(args))
end

function M.start_command(args)
  local configs = config.parse(args)
  if not configs then
    return false
  end
  return M.start(configs)
end

function M.start(...)
  local configs = core.merge_table(
    core.deepcopy(config.configs), ... or {}
  )
  if configs.path == '' then
    configs.path = vim.fn.getcwd()
  end
  configs.path = core.normalized_path(configs.path)

  configs.name = 'test'

  local buffer = Buffer.find(configs.name)
  if buffer then
    -- TODO: open action
  end
  action.start(configs)
  return true
end

return M
