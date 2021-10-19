local action = require 'vfiler/action'
local config = require 'vfiler/config'
local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local Buffer = require 'vfiler/buffer'

local M = {}

mapping.setup {
  main = {
    ['<CR>'] = [[:lua require'vfiler'.do_action('open')]],
    ['<Tab>'] = [[:lua require'vfiler'.do_action('switch_to_buffer')]],
    ['gg'] = [[:lua require'vfiler'.do_action('move_cursor_top')]],
    ['h'] = [[:lua require'vfiler'.do_action('close_tree_or_cd')]],
    ['j'] = [[:lua require'vfiler'.do_action('move_cursor_down', {true})]],
    ['k'] = [[:lua require'vfiler'.do_action('move_cursor_up', {true})]],
    ['l'] = [[:lua require'vfiler'.do_action('open_tree')]],
    ['G'] = [[:lua require'vfiler'.do_action('move_cursor_bottom')]],
    ['L'] = [[:lua require'vfiler'.do_action('change_drive')]],
    ['S'] = [[:lua require'vfiler'.do_action('change_sort')]],
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

function M.do_action(name, ...)
  action.do_action(name, ... or {})
end

function M.set_keymap(type, key, rhs)
  mapping.set(type, key, rhs)
end

return M
