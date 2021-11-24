local action = require 'vfiler/action'
local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local M = {}

-- Default configs
M.configs = {
  options = {
    auto_cd = false,
    columns = 'indent,icon,name,mode,size,time',
    header = true,
    listed = true,
    name = '',
    show_hidden_files = false,
    sort = 'name',
    direction = 'none',
    width = 90,
    height = 30,
    new = false,
    quit = true,
  },

  mappings = {
    ['.']         = action.toggle_show_hidden,
    ['<BS>']      = action.change_to_parent,
    ['<C-l>']     = action.reload,
    ['<C-p>']     = action.sync_with_current_filer,
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
    ['J']         = action.jump_to_directory,
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
    CursorHold = action.latest_update,
    FileType = action.reload,
    FocusGained = action.latest_update,
    VimResized = action.redraw_all,
  },
}

-- Convert command option string for completion
local command_option_names = {}
local command_not_option_names = {}

for name, value in pairs(M.configs.options) do
  local opname = name:gsub('_', '-')
  if type(value) == 'boolean' then
    table.insert(command_not_option_names, '-no-' .. opname)
  end
  table.insert(command_option_names, '-' .. opname)
end

local function complete_options(arglead)
  local target
  if arglead:find('^-no') then
    target = command_not_option_names
  else
    target = command_option_names
  end
  local list = {}
  for _, name in ipairs(target) do
    if name:find(arglead) then
      table.insert(list, name)
    end
  end
  if #list > 1 then
    table.sort(list)
  end
  return list
end

local function error(message)
  core.message.error('Argument error - %s', message)
end

local function normalize(value)
  if type(value) ~= 'string' then
    return value
  end

  local number = tonumber(value)
  if number then
    return number
  end

  if not core.is_windows then
    value = value:gsub('\\', '/')
  end
  return vim.fn.trim(value, ' "')
end

local function split(str_args)
  local args = {}
  local pos = 1
  local escaped, in_dquote = false, false

  for i = 1, #str_args do
    local char = str_args:sub(i, i)
    if char == ' ' and not (escaped or in_dquote) then
      table.insert(args, str_args:sub(pos, i - 1))
      pos = i + 1 -- reset position
    elseif char == '"' then
      in_dquote = not in_dquote
    end
    escaped = char == '\\'
  end
  -- insert the rest of string
  table.insert(args, str_args:sub(pos))
  return args
end

local function parse_option(arg)
  local key, value = arg:match('^%-([%-%w]+)=(.+)')
  if key then
    value = normalize(value)
  else
    key = arg:match('^%-no%-(%g+)')
    if key then
      value = false
    else
      key = arg:sub(2) -- remove '-'
      value = true
    end
  end
  -- replace for option property name
  return key:gsub('%-', '_'), value, key
end

function M.complete(arglead)
  local list = {}

  if #arglead > 0 and arglead:sub(1, 1) == '-' then
    -- Complete options
    return vim.to_vimlist(complete_options(arglead))
  end

  -- Complete directory path
  local condidate_files = vim.from_vimlist(
    vim.fn.glob(arglead .. '*', 1, 1, 1)
    )
  for _, path in ipairs(condidate_files) do
    if core.path.isdirectory(path) then
      table.insert(list, core.path.normalize(path))
    end
  end
  if #list > 1 then
    table.sort(list)
  end
  return vim.to_vimlist(list)
end

--- Parse command line arguments strings
---@param str_args string
function M.parse_options(str_args)
  local options = core.table.copy(M.configs.options)
  if not str_args or #str_args == 0 then
    return options, nil
  end

  local args = split(str_args)
  local path = ''

  for _, arg in ipairs(args) do
    if arg:sub(1, 1) == '-' then
      local name, value, key = parse_option(arg)
      if options[name] == nil then
        error(string.format('Unknown "%s" option.', key))
        return nil
      elseif type(value) ~= type(options[name]) then
        error(string.format('Illegal option value. (%s)', value))
        return nil
      end
      options[name] = value
    else
      if #path > 0 then
        error('The path specification is duplicated.')
        return nil
      end
      path = normalize(arg)
    end
  end
  return options, path
end

function M.setup(configs)
  core.table.merge(M.configs, configs)
end

return M
