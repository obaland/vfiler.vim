local action = require 'vfiler/action'
local config = require 'vfiler/config'
local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local VFiler = require 'vfiler/vfiler'

local M = {}

config.setup {
  mappings = {
    ['.']         = action.toggle_show_hidden,
    ['<BS>']      = action.change_to_parent,
    ['<C-j>']     = action.jump_to_directory,
    ['<CR>']      = action.open,
    ['<S-Space>'] = action.toggle_select_up,
    ['<Space>']   = action.toggle_select_down,
    ['<Tab>']     = action.switch_to_filer,
    ['~']         = action.jump_to_home,
    ['*']         = action.toggle_select_all,
    ['\\']        = action.jump_to_root,
    ['cc']        = action.copy_to_filer,
    ['dd']        = action.delete,
    ['gg']        = action.move_cursor_top,
    ['h']         = action.close_tree_or_cd,
    ['j']         = action.loop_cursor_down,
    ['k']         = action.loop_cursor_up,
    ['l']         = action.open_tree,
    ['mm']        = action.move_to_filer,
    ['q']         = action.quit,
    ['r']         = action.rename,
    ['s']         = action.open_by_split,
    ['t']         = action.open_by_tabpage,
    ['v']         = action.open_by_vsplit,
    ['x']         = action.execute_file,
    ['yy']        = action.yank_path,
    ['C']         = action.copy,
    ['D']         = action.delete,
    ['G']         = action.move_cursor_bottom,
    ['K']         = action.new_directory,
    ['L']         = action.switch_to_drive,
    ['M']         = action.move,
    ['N']         = action.new_file,
    ['P']         = action.paste,
    ['S']         = action.change_sort,
    ['U']         = action.clear_selected_all,
    ['YY']        = action.yank_name,
  },

  events = {
    BufEnter = action.reload,
    FocusGained = action.reload_all,
    VimResized = action.redraw_all,
  },
}

function M.parse_command_args(args)
  return vim.to_vimdict(config.parse_options(args))
end

function M.start_command(args)
  local options, dirpath = config.parse_options(args)
  if not options then
    return false
  end
  local configs = {
    options = options,
    mappings = core.table.copy(config.configs.mappings),
  }
  return M.start(dirpath, configs)
end

function M.start(...)
  local args = {...}
  local configs = core.table.merge(args[2] or {}, config.configs)
  local options = configs.options

  local dirpath = args[1]
  if not dirpath or dirpath == '' then
    dirpath = vim.fn.getcwd()
  end

  -- TODO:
  options.name = 'test'

  local vfiler = VFiler.find(options.name)
  if vfiler then
    -- TODO: open action
  end
  action.start(dirpath, configs)
  return true
end

return M
