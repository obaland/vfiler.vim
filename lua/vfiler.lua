local action = require 'vfiler/action'
local config = require 'vfiler/config'
local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local VFiler = require 'vfiler/vfiler'

local M = {}

local function _do_action(name, ...)
  local func = [[:lua require('vfiler/action').do_action]]
  local args = ''
  if ... then
    args = ([[('%s', %s)]]):format(name, ...)
  else
    args = ([[('%s')]]):format(name)
  end
  return func .. args
end

mapping.setup {
  main = {
    ['.']         = _do_action('toggle_show_hidden'),
    ['<CR>']      = _do_action('open'),
    ['<S-Space>'] = _do_action('toggle_select', [['up']]),
    ['<Space>']   = _do_action('toggle_select', [['down']]),
    ['<Tab>']     = _do_action('switch_to_filer'),
    ['gg']        = _do_action('move_cursor_top'),
    ['h']         = _do_action('close_tree_or_cd'),
    ['j']         = _do_action('move_cursor_down', 'true'),
    ['k']         = _do_action('move_cursor_up', 'true'),
    ['l']         = _do_action('open_tree'),
    ['q']         = _do_action('quit'),
    ['D']         = _do_action('delete'),
    ['G']         = _do_action('move_cursor_bottom'),
    ['K']         = _do_action('new_directory'),
    ['L']         = _do_action('change_drive'),
    ['N']         = _do_action('new_file'),
    ['S']         = _do_action('change_sort'),
  },
}

function M.parse_command_args(args)
  return vim.vim_dict(config.parse(args))
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

  local vfiler = VFiler.find(configs.name)
  if vfiler then
    -- TODO: open action
  end
  action.start(configs)
  return true
end

return M
