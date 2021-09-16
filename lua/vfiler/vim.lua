local M = {}

M.fn = vim.fn

if vim.fn.has('nvim') == 1 then
  M.command = vim.api.nvim_command -- Alias

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

  function M.get_buf_option_value(name, value)
    return vim.api.nvim_buf_get_option(0, name)
  end
  M.get_buf_option_boolean = M.get_buf_option_value -- Alias
  function M.set_buf_option(name, value)
    vim.api.nvim_buf_set_option(0, name, value)
  end

  function M.get_win_option_value(name)
    return vim.api.nvim_win_get_option(0, name)
  end
  M.get_win_option_boolean = M.get_win_option_value -- Alias
  function M.set_win_option(name, value)
    vim.api.nvim_win_set_option(0, name, value)
  end
else
  M.command = vim.command --Alias

  local function get_option(prefix, name)
    return vim.eval(prefix .. name)
  end

  local function set_option(command, name, value)
    local option = ''
    if type(value) == 'boolean' then
      option = value and name or 'no' .. name
    else
      option = string.format('%s=%s', name, value)
    end
    vim.command(command .. ' ' .. option)
  end

  function M.get_global_option_value(name)
    return get_option('&g:', name)
  end
  function M.get_global_option_boolean(name)
    return M.get_global_option_value(name) == 1 and true or false
  end
  function M.set_global_option(name, value)
    set_option('setglobal', name, value)
  end

  function M.get_option_value(name)
    return get_option('&', name)
  end
  function M.get_option_boolean(name)
    return M.get_option_value(name) == 1 and true or false
  end
  function M.set_option(name, value)
    set_option('set', name, value)
  end

  M.get_buf_option_value = M.get_option_value -- Alias
  M.get_buf_option_boolean = M.get_option_boolean -- Alias
  function M.set_buf_option(name, value)
    set_option('setlocal', name, value)
  end

  M.get_win_option_value = M.get_option_value -- Alias
  M.get_win_option_boolean = M.get_option_boolean -- Alias
  M.set_win_option = M.set_buf_option -- Alias
end

return M
