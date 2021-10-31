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
function M.set_global_option(name, value)
  vim.command(M.command_set_option('setglobal', name, value))
end

function M.get_option_value(name)
  return M.get_option('&', name)
end
function M.get_option_boolean(name)
  return M.get_option_value(name) == 1 and true or false
end
function M.set_option(name, value)
  vim.command(M.command_set_option('set', name, value))
end

------------------------------------------------------------------------------
-- Buffer option
------------------------------------------------------------------------------
M.get_buf_option_value = M.get_option_value -- Alias
M.get_buf_option_boolean = M.get_option_boolean -- Alias
function M.set_buf_option(name, value)
  vim.command(M.command_set_option('setlocal', name, value))
end

------------------------------------------------------------------------------
-- Window option
------------------------------------------------------------------------------
M.get_win_option_value = M.get_option_value -- Alias
M.get_win_option_boolean = M.get_option_boolean -- Alias
M.set_win_option = M.set_buf_option -- Alias

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
function M.vim_list(data)
  return data and vim.list(data) or nil
end
function M.vim_dict(data)
  return data and vim.dict(data) or nil
end

return M
