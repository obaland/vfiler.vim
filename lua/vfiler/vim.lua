local M = {}

M.fn = vim.fn

if vim.fn.has('nvim') == 1 then
  ----------------------------------------------------------------------------
  -- Neovim
  ----------------------------------------------------------------------------
  M.api = vim.api -- Alias
  M.command = vim.api.nvim_command -- Alias

  -- Global option
  M.get_global_option_value = vim.api.nvim_get_option -- Alias
  M.get_global_option_boolean = vim.api.nvim_get_option -- Alias
  M.set_global_option = vim.api.nvim_set_option -- Alias

  function M.get_option_value(name)
    return vim.o[name]
  end
  M.get_option_boolean = M.get_option_value -- Alias

  function M.set_option(name, value)
    vim.o[name] = value
  end

  -- Buffer option
  function M.get_buf_option_value(name, value)
    return vim.api.nvim_buf_get_option(0, name)
  end
  M.get_buf_option_boolean = M.get_buf_option_value -- Alias
  function M.set_buf_option(name, value)
    vim.api.nvim_buf_set_option(0, name, value)
  end

  -- Window option
  function M.get_win_option_value(name)
    return vim.api.nvim_win_get_option(0, name)
  end
  M.get_win_option_boolean = M.get_win_option_value -- Alias
  function M.set_win_option(name, value)
    vim.api.nvim_win_set_option(0, name, value)
  end

  -- Key mapping
  M.set_keymap = vim.api.nvim_set_keymap
  function M.set_buf_keymap(mode, lhs, rhs, opts)
    vim.api.nvim_buf_set_keymap(0, mode, lhs, rhs, opts)
  end

  -- lua data to vim data
  function M.vim_list(data)
    return data
  end
  function M.vim_dict(data)
    return data
  end

else
  ----------------------------------------------------------------------------
  -- Vim
  ----------------------------------------------------------------------------

  M.command = vim.command --Alias

  -- Global option
  function M.get_option(prefix, name)
    return vim.eval(prefix .. name)
  end

  function M.command_set_option(command, name, value)
    local option = ''
    if type(value) == 'boolean' then
      option = value and name or 'no' .. name
    else
      option = string.format('%s=%s', name, vim.fn.escape(value, ' '))
    end
    return command .. ' ' .. option
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

  -- Buffer option
  M.get_buf_option_value = M.get_option_value -- Alias
  M.get_buf_option_boolean = M.get_option_boolean -- Alias
  function M.set_buf_option(name, value)
    vim.command(M.command_set_option('setlocal', name, value))
  end

  -- Window option
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

  -- Lua data to Vim data
  function M.vim_list(data)
    return data and vim.list(data) or nil
  end
  function M.vim_dict(data)
    return data and vim.dict(data) or nil
  end
end

-- Utilities
function M.commands(cmds)
  M.command(table.concat(cmds, ' | '))
end

function M.set_options(options)
  for key, value in pairs(options) do
    M.set_option(key, value)
  end
end

function M.set_buf_options(options)
  for key, value in pairs(options) do
    M.set_buf_option(key, value)
  end
end

function M.set_win_options(options)
  for key, value in pairs(options) do
    M.set_win_option(key, value)
  end
end

function M.win_executes(window, cmds)
  M.fn.win_execute(window, table.concat(cmds, ' | '))
end

return M
