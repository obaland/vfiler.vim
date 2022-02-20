local action = require('vfiler/action')
local core = require('vfiler/libs/core')
local event = require('vfiler/actions/event')
local vim = require('vfiler/libs/vim')

local M = {}

-- Default configs
M.configs = {
  options = {
    auto_cd = false,
    auto_resize = false,
    columns = 'indent,icon,name,mode,size,time',
    header = true,
    keep = false,
    listed = true,
    name = '',
    session = 'buffer',
    show_hidden_files = false,
    sort = 'name',
    layout = 'none',
    width = 90,
    height = 30,
    new = false,
    quit = true,
    row = 0,
    col = 0,
    blend = 0,
    border = 'rounded',
    zindex = 200,
    git = {
      enabled = true,
      ignored = true,
      untracked = true,
    },
    preview = {
      layout = 'floating',
      width = 0,
      height = 0,
    },
  },

  mappings = {
    ['.'] = action.toggle_show_hidden,
    ['<BS>'] = action.change_to_parent,
    ['<C-l>'] = action.reload,
    ['<C-p>'] = action.toggle_auto_preview,
    ['<C-r>'] = action.sync_with_current_filer,
    ['<C-s>'] = action.toggle_sort,
    ['<CR>'] = action.open,
    ['<S-Space>'] = function(vfiler, context, view)
      action.toggle_select(vfiler, context, view)
      action.move_cursor_up(vfiler, context, view)
    end,
    ['<Space>'] = function(vfiler, context, view)
      action.toggle_select(vfiler, context, view)
      action.move_cursor_down(vfiler, context, view)
    end,
    ['<Tab>'] = action.switch_to_filer,
    ['~'] = action.jump_to_home,
    ['*'] = action.toggle_select_all,
    ['\\'] = action.jump_to_root,
    ['cc'] = action.copy_to_filer,
    ['dd'] = action.delete,
    ['gg'] = action.move_cursor_top,
    ['b'] = action.list_bookmark,
    ['h'] = action.close_tree_or_cd,
    ['j'] = action.loop_cursor_down,
    ['k'] = action.loop_cursor_up,
    ['l'] = action.open_tree,
    ['mm'] = action.move_to_filer,
    ['p'] = action.toggle_preview,
    ['q'] = action.quit,
    ['r'] = action.rename,
    ['s'] = action.open_by_split,
    ['t'] = action.open_by_tabpage,
    ['v'] = action.open_by_vsplit,
    ['x'] = action.execute_file,
    ['yy'] = action.yank_path,
    ['B'] = action.add_bookmark,
    ['C'] = action.copy,
    ['D'] = action.delete,
    ['G'] = action.move_cursor_bottom,
    ['J'] = action.jump_to_directory,
    ['K'] = action.new_directory,
    ['L'] = action.switch_to_drive,
    ['M'] = action.move,
    ['N'] = action.new_file,
    ['P'] = action.paste,
    ['S'] = action.change_sort,
    ['U'] = action.clear_selected_all,
    ['YY'] = action.yank_name,
  },

  events = {
    vfiler = {
      BufEnter = action.redraw,
      BufLeave = event.close_floating,
      CursorHold = event.latest_update,
      FocusGained = event.latest_update,
      TabLeave = event.close_floating,
      VimResized = action.redraw,
    },

    vfiler_preview = {
      BufLeave = action.close_preview,
      CursorMoved = action.preview_cursor_moved,
    },
  },
}

-- Convert command option string for completion
local command_option_names = {}

local function insert_option_name(names, key, value)
  local opname = key:gsub('_', '-')
  if type(value) == 'boolean' then
    table.insert(names, '-no-' .. opname)
    table.insert(names, '-' .. opname)
  else
    table.insert(names, '-' .. opname .. '=')
  end
end

for name, value in pairs(M.configs.options) do
  if type(value) == 'table' then
    for k, v in pairs(value) do
      local opname = name .. '_' .. k
      insert_option_name(command_option_names, opname, v)
    end
  else
    insert_option_name(command_option_names, name, value)
  end
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

local function split_args(str_args)
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

local function set_option(options, name, value, key)
  local defalut = options[name]
  if defalut ~= nil then
    if type(value) ~= type(defalut) then
      error(
        ('The "%s" value of the "%s" option is invalid.'):format(value, name)
      )
      return false
    end
    options[name] = value
    return true
  end

  -- nest option
  local index = name:find('_')
  if not index then
    error(('Unknown "%s" option.'):format(key))
    return false
  end
  local top_name = name:sub(1, index - 1)
  local nest_name = name:sub(index + 1)
  local top = options[top_name]
  if not (top and nest_name and top[nest_name] ~= nil) then
    error(('Unknown "%s" option.'):format(key))
    return false
  end
  top[nest_name] = value
  return true
end

--- Clear all key mappings
function M.clear_mappings()
  M.configs.mappings = {}
end

function M.complete(arglead)
  if #arglead == 0 or arglead:sub(1, 1) ~= '-' then
    return vim.list({})
  end

  local pattern = '^' .. core.string.pesc(arglead)
  local list = {}
  for _, name in ipairs(command_option_names) do
    if name:match(pattern) then
      table.insert(list, name)
    end
  end
  if #list > 1 then
    table.sort(list)
  end
  return vim.list(list)
end

--- Parse command line arguments strings
---@param str_args string
function M.parse_options(str_args)
  local options = core.table.copy(M.configs.options)
  if not str_args or #str_args == 0 then
    return options, nil
  end

  local args = split_args(str_args)
  local path = ''

  for _, arg in ipairs(args) do
    if arg:sub(1, 1) == '-' then
      local name, value, key = parse_option(arg)
      if not set_option(options, name, value, key) then
        return nil
      end
    else
      if #path > 0 then
        error('The path specification is duplicated.')
        return nil
      end
      -- escaped space
      path = normalize(arg:gsub([[\ ]], ' '))
    end
  end
  return options, path
end

--- Setup vfiler configs
---@param configs table
function M.setup(configs)
  core.table.merge(M.configs, configs)
  return M.configs
end

--- Unmap the specified key
---@param key string
function M.unmap(key)
  M.configs.mappings[key] = nil
end

return M
