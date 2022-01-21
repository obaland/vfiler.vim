local M = {}

-- Alias
M.command = vim.command
M.fn = vim.fn
M.eval = vim.eval

------------------------------------------------------------------------------
-- Options
------------------------------------------------------------------------------
local function get_option(prefix, name)
  return vim.eval(prefix .. name)
end

function M.get_global_option(name)
  return get_option('&g:', name)
end
function M.get_global_option_boolean(name)
  return M.get_global_option(name) == 1
end

function M.get_option(name)
  return get_option('&', name)
end
function M.get_option_boolean(name)
  return M.get_option(name) == 1
end

------------------------------------------------------------------------------
-- Key mapping
------------------------------------------------------------------------------

local function set_keymap(mode, lhs, rhs, opts)
  local command
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
    'silent',
    'nowait',
    'special',
    'script',
    'expr',
    'unique',
  }
  for _, arg in ipairs(args_keys) do
    if opts[arg] then
      args = args .. string.format('<%s>', arg)
    end
  end
  return string.format('%s %s %s %s', command, args, lhs, rhs)
end

local function del_keymap(mode, lhs, buffer)
  local command
  if mode == '!' then
    command = 'map!'
  else
    command = mode .. 'map'
  end
  if buffer then
    command = command .. ' <buffer>'
  end
  return 'silent ' .. command .. ' ' .. lhs
end

function M.set_keymap(mode, lhs, rhs, opts)
  opts._buffer = false
  vim.command(set_keymap(mode, lhs, rhs, opts))
end
function M.set_buf_keymap(buffer, mode, lhs, rhs, opts)
  local winid = vim.fn.bufwinid(buffer)
  assert(winid >= 0)
  opts._buffer = true
  vim.fn.win_execute(winid, set_keymap(mode, lhs, rhs, opts))
end

function M.del_keymap(mode, lhs)
  vim.command(del_keymap(mode, lhs))
end
function M.del_buf_keymap(buffer, mode, lhs)
  local winid = vim.fn.bufwinid(buffer)
  assert(winid >= 0)
  vim.fn.win_execute(winid, del_keymap(mode, lhs, true))
end

------------------------------------------------------------------------------
-- Lua data to Vim data
------------------------------------------------------------------------------
function M.to_vimlist(data)
  if vim.type(data) == 'list' then
    return data
  end
  return vim.list(data)
end
function M.to_vimdict(data)
  if vim.type(data) == 'dict' then
    return data
  end
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
