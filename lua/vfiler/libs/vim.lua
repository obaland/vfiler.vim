local is_nvim = vim.fn.has('nvim') == 1

local M = {}

------------------------------------------------------------------------------
-- Aliases
------------------------------------------------------------------------------
M.fn = vim.fn
M.v = vim.v
if is_nvim then
  M.command = vim.api.nvim_command
  M.nvim = vim
else
  M.command = vim.command
end

------------------------------------------------------------------------------
-- Options
------------------------------------------------------------------------------
if is_nvim then
  -- for Neovim
  M.get_option = vim.api.nvim_get_option
  M.get_flag_option = vim.api.nvim_get_option
else
  -- for Vim
  function M.get_option(name)
    return vim.eval('&g:' .. name)
  end
  function M.get_flag_option(name)
    return M.get_option(name) == 1
  end
end

function M.get_buf_option(buffer, name)
  return M.fn.getbufvar(buffer, '&' .. name)
end
function M.get_buf_flag_option(buffer, name)
  return M.get_buf_option(buffer, name) == 1
end
function M.get_win_option(window, name)
  return M.fn.getwinvar(window, '&' .. name)
end
function M.get_win_flag_option(window, name)
  return M.get_win_option(window, name) == 1
end

local function set_option_command(command, name, value)
  local option
  if type(value) == 'boolean' then
    option = value and name or 'no' .. name
  else
    option = ('%s=%s'):format(name, M.fn.escape(value, ' '))
  end
  return command .. ' ' .. option
end

function M.set_option(name, value)
  M.command(set_option_command('setglobal', name, value))
end
function M.set_buf_option(buffer, name, value)
  if type(value) == 'boolean' then
    value = value and 1 or 0
  end
  M.fn.setbufvar(buffer, '&' .. name, value)
end
function M.set_win_option(window, name, value)
  if type(value) == 'boolean' then
    value = value and 1 or 0
  end
  M.fn.setwinvar(window, '&' .. name, value)
end

function M.set_options(options)
  for name, value in pairs(options) do
    M.set_option(name, value)
  end
end
function M.set_buf_options(buffer, options)
  for name, value in pairs(options) do
    M.set_buf_option(buffer, name, value)
  end
end
function M.set_win_options(window, options)
  for name, value in pairs(options) do
    M.set_win_option(window, name, value)
  end
end

------------------------------------------------------------------------------
-- Key mapping
------------------------------------------------------------------------------
if is_nvim then
  -- for Neovim
  M.set_keymap = vim.api.nvim_set_keymap
  function M.set_buf_keymap(buffer, mode, lhs, rhs, opts)
    -- match behavior with vim
    assert(vim.fn.bufwinid(buffer) >= 0)
    vim.api.nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
  end

  M.del_keymap = vim.api.nvim_del_keymap
  function M.del_buf_keymap(buffer, mode, lhs)
    -- match behavior with vim
    assert(vim.fn.bufwinid(buffer) >= 0)
    vim.api.nvim_buf_del_keymap(buffer, mode, lhs)
  end
else
  -- for Vim
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
    vim.fn.win_execute(winid, set_keymap(mode, lhs, rhs, opts), 'silent')
  end

  function M.del_keymap(mode, lhs)
    vim.command(del_keymap(mode, lhs))
  end
  function M.del_buf_keymap(buffer, mode, lhs)
    local winid = vim.fn.bufwinid(buffer)
    assert(winid >= 0)
    vim.fn.win_execute(winid, del_keymap(mode, lhs, true), 'silent')
  end
end

------------------------------------------------------------------------------
-- List type
------------------------------------------------------------------------------
if is_nvim then
  -- for Neovim
  M.list = setmetatable({}, {
    __call = function(t, list)
      return list or {}
    end,
  })

  function M.list.from(data)
    return data or {}
  end
else
  -- for Vim
  M.list = setmetatable({}, {
    __call = function(t, list)
      if vim.type(list) == 'list' then
        return list
      end
      return vim.list(list)
    end,
  })

  function M.list.from(list)
    if vim.type(list) == 'table' then
      return list
    end
    local t = {}
    for value in list() do
      table.insert(t, value)
    end
    return t
  end
end

------------------------------------------------------------------------------
-- Dictionary type
------------------------------------------------------------------------------
if is_nvim then
  M.dict = setmetatable({}, {
    __call = function(t, dict)
      return dict or {}
    end,
  })

  function M.dict.from(data)
    return data or {}
  end
else
  M.dict = setmetatable({}, {
    __call = function(t, dict)
      if vim.type(dict) == 'dict' then
        return dict
      end
      return vim.dict(dict)
    end,
  })

  function M.dict.from(dict)
    if vim.type(dict) == 'table' then
      return dict
    end
    local t = {}
    for key, value in dict() do
      t[key] = value
    end
    return t
  end
end

------------------------------------------------------------------------------
-- Utilities
------------------------------------------------------------------------------
function M.commands(cmds)
  for _, cmd in ipairs(cmds) do
    M.command(cmd)
  end
end

function M.win_executes(window, cmds, silent)
  silent = silent or 'silent'
  for _, cmd in ipairs(cmds) do
    M.fn.win_execute(window, cmd, silent)
  end
end

return M
