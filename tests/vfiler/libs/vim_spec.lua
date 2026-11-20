describe('Vim keymap removal', function()
  local adapter, original_window, buffers, windows
  local lhs = '<Plug>(vfiler-unmap-target)'
  local other = '<Plug>(vfiler-unmap-other)'
  local modes = { 'n', 'i', 'c' }

  -- Load the Vim branch without changing the shared vim global.
  -- Execute its commands against Neovim's actual mapping tables.
  local function load_adapter()
    local vim_functions = setmetatable({
      has = function(feature)
        if feature == 'nvim' then
          return 0
        end
        return vim.fn.has(feature)
      end,
    }, { __index = vim.fn })
    local vim_compatibility = setmetatable({
      fn = vim_functions,
      command = vim.api.nvim_command,
      eval = vim.api.nvim_eval,
    }, { __index = vim })
    local environment = setmetatable({
      vim = vim_compatibility,
    }, { __index = _G })
    local chunk = assert(loadfile('lua/vfiler/libs/vim.lua'))
    setfenv(chunk, environment)
    return chunk()
  end

  local function open_window()
    vim.cmd('botright new')
    local window = vim.api.nvim_get_current_win()
    local buffer = vim.api.nvim_get_current_buf()
    table.insert(windows, window)
    table.insert(buffers, buffer)
    return buffer, window
  end

  local function buffer_map(buffer, mode, key)
    for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(buffer, mode)) do
      if mapping.lhs == key then
        return mapping.rhs
      end
    end
    return nil
  end

  local function global_map(mode, key)
    for _, mapping in ipairs(vim.api.nvim_get_keymap(mode)) do
      if mapping.lhs == key then
        return mapping.rhs
      end
    end
    return nil
  end

  before_each(function()
    original_window = vim.api.nvim_get_current_win()
    buffers, windows = {}, {}
    open_window()
    adapter = load_adapter()
  end)

  after_each(function()
    for _, mode in ipairs(modes) do
      pcall(vim.api.nvim_del_keymap, mode, lhs)
      pcall(vim.api.nvim_del_keymap, mode, other)
    end
    for i = #windows, 1, -1 do
      if vim.api.nvim_win_is_valid(windows[i]) then
        vim.api.nvim_win_close(windows[i], true)
      end
    end
    for _, buffer in ipairs(buffers) do
      if vim.api.nvim_buf_is_valid(buffer) then
        vim.api.nvim_buf_delete(buffer, { force = true })
      end
    end
    if vim.api.nvim_win_is_valid(original_window) then
      vim.api.nvim_set_current_win(original_window)
    end
  end)

  for _, mode in ipairs(modes) do
    it('removes a global mapping in mode ' .. mode, function()
      adapter.set_keymap(mode, lhs, 'GLOBAL', { noremap = true })
      assert.are.equal('GLOBAL', vim.fn.maparg(lhs, mode))

      adapter.del_keymap(mode, lhs)

      assert.are.equal('', vim.fn.maparg(lhs, mode))
    end)

    it('removes a buffer mapping in mode ' .. mode, function()
      local buffer = buffers[1]
      adapter.set_buf_keymap(buffer, mode, lhs, 'LOCAL', { noremap = true })
      assert.are.equal('LOCAL', buffer_map(buffer, mode, lhs))

      adapter.del_buf_keymap(buffer, mode, lhs)

      assert.is_nil(buffer_map(buffer, mode, lhs))
    end)
  end

  it('removes insert and command-line mappings with mode !', function()
    adapter.set_keymap('!', lhs, 'BOTH', { noremap = true })
    assert.are.equal('BOTH', vim.fn.maparg(lhs, 'i'))
    assert.are.equal('BOTH', vim.fn.maparg(lhs, 'c'))

    adapter.del_keymap('!', lhs)

    assert.are.equal('', vim.fn.maparg(lhs, 'i'))
    assert.are.equal('', vim.fn.maparg(lhs, 'c'))
  end)

  it('removes buffer insert and command-line mappings with mode !', function()
    local buffer = buffers[1]
    adapter.set_buf_keymap(buffer, '!', lhs, 'BOTH', { noremap = true })

    adapter.del_buf_keymap(buffer, '!', lhs)

    assert.is_nil(buffer_map(buffer, 'i', lhs))
    assert.is_nil(buffer_map(buffer, 'c', lhs))
  end)

  it('keeps unrelated global mappings', function()
    adapter.set_keymap('n', lhs, 'TARGET', { noremap = true })
    adapter.set_keymap('n', other, 'OTHER', { noremap = true })

    adapter.del_keymap('n', lhs)

    assert.are.equal('', vim.fn.maparg(lhs, 'n'))
    assert.are.equal('OTHER', vim.fn.maparg(other, 'n'))
  end)

  it('keeps the global mapping when removing a buffer mapping', function()
    local buffer = buffers[1]
    adapter.set_keymap('n', lhs, 'GLOBAL', { noremap = true })
    adapter.set_buf_keymap(buffer, 'n', lhs, 'LOCAL', { noremap = true })

    adapter.del_buf_keymap(buffer, 'n', lhs)

    assert.is_nil(buffer_map(buffer, 'n', lhs))
    assert.are.equal('GLOBAL', vim.fn.maparg(lhs, 'n'))
  end)

  it('keeps buffer mappings when removing a global mapping', function()
    local buffer = buffers[1]
    adapter.set_keymap('n', lhs, 'GLOBAL', { noremap = true })
    adapter.set_buf_keymap(buffer, 'n', lhs, 'LOCAL', { noremap = true })

    adapter.del_keymap('n', lhs)

    assert.is_nil(global_map('n', lhs))
    assert.are.equal('LOCAL', buffer_map(buffer, 'n', lhs))
  end)

  it('only removes mappings from the requested buffer', function()
    local first = buffers[1]
    adapter.set_buf_keymap(first, 'n', lhs, 'FIRST', { noremap = true })
    local second, current_window = open_window()
    adapter.set_buf_keymap(second, 'n', lhs, 'SECOND', { noremap = true })

    adapter.del_buf_keymap(first, 'n', lhs)

    assert.is_nil(buffer_map(first, 'n', lhs))
    assert.are.equal('SECOND', buffer_map(second, 'n', lhs))
    assert.are.equal(current_window, vim.api.nvim_get_current_win())
  end)

  it('removes mappings through Buffer:undefine_mappings', function()
    local environment = setmetatable({
      require = function(name)
        if name == 'vfiler/libs/vim' then
          return adapter
        end
        return require(name)
      end,
    }, { __index = _G })
    local chunk = assert(loadfile('lua/vfiler/buffer.lua'))
    setfenv(chunk, environment)
    local Buffer = chunk()
    local buffer = setmetatable({ number = buffers[1] }, Buffer)
    local mappings = {
      [lhs] = function() end,
      [other] = function() end,
    }
    buffer:define_mappings(mappings, 'vfiler_test_mapping')
    assert.is_not_nil(buffer_map(buffer.number, 'n', lhs))
    assert.is_not_nil(buffer_map(buffer.number, 'n', other))

    buffer:undefine_mappings(mappings)

    assert.is_nil(buffer_map(buffer.number, 'n', lhs))
    assert.is_nil(buffer_map(buffer.number, 'n', other))
  end)
end)
