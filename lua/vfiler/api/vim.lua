local M = {}

-- Alias
M.command = vim.command
M.fn = vim.fn

------------------------------------------------------------------------------
-- Global option
------------------------------------------------------------------------------
function M.get_option(prefix, name)
  return vim.eval(prefix .. name)
end

function M.get_global_option_value(name)
  return M.get_option('&g:', name)
end
function M.get_global_option_boolean(name)
  return M.get_global_option_value(name) == 1 and true or false
end

function M.get_option_value(name)
  return M.get_option('&', name)
end
function M.get_option_boolean(name)
  return M.get_option_value(name) == 1 and true or false
end

------------------------------------------------------------------------------
-- Buffer option
------------------------------------------------------------------------------
M.get_buf_option_value = M.get_option_value -- Alias
M.get_buf_option_boolean = M.get_option_boolean -- Alias

------------------------------------------------------------------------------
-- Window option
------------------------------------------------------------------------------
M.get_win_option_value = M.get_option_value -- Alias
M.get_win_option_boolean = M.get_option_boolean -- Alias

-- Key mapping
local function set_keymap(mode, lhs, rhs, opts)
  local command = ''
  if opts.noremap then
    if mode == '!' then
      command = 'noremap!'
    else
      command = mode .. 'noremap'
    end
  elseif mode == '!' then
    command = 'map!'
  else
    command = mode .. 'map'
  end

  -- special arguments
  local args = opts._buffer and '<buffer>' or ''
  local args_keys = {
    'silent', 'nowait', 'special', 'script', 'expr', 'unique'
  }
  for _, arg in ipairs(args_keys) do
    if opts[arg] then
      args = args .. string.format('<%s>', arg)
    end
  end
  vim.command(string.format('%s %s %s %s', command, args, lhs, rhs))
end

function M.set_keymap(mode, lhs, rhs, opts)
  opts._buffer = false
  set_keymap(mode, lhs, rhs, opts)
end
function M.set_buf_keymap(mode, lhs, rhs, opts)
  opts._buffer = true
  set_keymap(mode, lhs, rhs, opts)
end

------------------------------------------------------------------------------
-- Lua data to Vim data
------------------------------------------------------------------------------
function M.to_vimlist(data)
  return vim.list(data)
end
function M.to_vimdict(data)
  return vim.dict(data)
end

------------------------------------------------------------------------------
-- Vim data to Lua data
------------------------------------------------------------------------------
function M.from_vimlist(data)
  local t = {}
  for value in data() do
    table.insert(t, value)
  end
  return t
end
function M.from_vimdict(data)
  local t = {}
  for key, value in data() do
    t[key] = value
  end
  return t
end

return M
