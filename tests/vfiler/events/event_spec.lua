local event = require('vfiler/events/event')

describe('event registration lifecycle', function()
  local buffers, original_handle, dispatches
  local first_group = 'vfiler_event_test_first'
  local other_group = 'vfiler_event_test_other'

  local function group_name(group, buffer)
    return buffer > 0 and group .. '_' .. buffer or group
  end

  local function exists(group, buffer)
    return vim.fn.exists('#' .. group_name(group, buffer)) == 1
  end

  local function commands(group, buffer)
    if not exists(group, buffer) then
      return {}
    end
    return vim.api.nvim_get_autocmds({
      group = group_name(group, buffer),
    })
  end

  local function count_id(group_id)
    local count = 0
    for _, command in ipairs(vim.api.nvim_get_autocmds({})) do
      if command.group == group_id then
        count = count + 1
      end
    end
    return count
  end

  local function fire(name, buffer)
    local options = { modeline = false }
    if buffer > 0 then
      options.buffer = buffer
    elseif name == 'User' then
      options.pattern = 'VFilerEventProbe'
    end
    vim.api.nvim_exec_autocmds(name, options)
  end

  local function register(group, name, buffer, callback)
    event.register(group, {
      { event = name, callback = callback or function() end },
    }, buffer)
    return commands(group, buffer)[1].group
  end

  before_each(function()
    buffers = {
      vim.api.nvim_create_buf(false, true),
      vim.api.nvim_create_buf(false, true),
    }
    dispatches = 0
    original_handle = event._handle
    event._handle = function(...)
      dispatches = dispatches + 1
      return original_handle(...)
    end
  end)

  after_each(function()
    event._handle = original_handle
    event.clear(0)
    for _, buffer in ipairs(buffers) do
      event.clear(buffer)
    end
    -- Clean up test groups even when the implementation leaves them behind.
    for _, group in ipairs({ first_group, other_group }) do
      for _, buffer in ipairs({ 0, buffers[1], buffers[2] }) do
        if exists(group, buffer) then
          vim.api.nvim_del_augroup_by_name(group_name(group, buffer))
        end
      end
    end
    for _, buffer in ipairs(buffers) do
      vim.api.nvim_buf_delete(buffer, { force = true })
    end
  end)

  for _, scope in ipairs({ 'global', 'buffer' }) do
    describe(scope, function()
      local function scope_values()
        if scope == 'global' then
          return 0, 'User', 'CursorHold'
        end
        return buffers[1], 'BufEnter', 'BufLeave'
      end

      it('dispatches a registered event once', function()
        local buffer, name = scope_values()
        local calls = 0
        register(first_group, name, buffer, function()
          calls = calls + 1
        end)

        fire(name, buffer)

        assert.are.equal(1, calls)
        assert.are.equal(1, dispatches)
      end)

      it('unregisters the commands and deletes their group', function()
        local buffer, name = scope_values()
        local id = register(first_group, name, buffer)
        event.unregister(first_group, buffer)

        assert.are.equal(0, count_id(id))
        assert.is_false(exists(first_group, buffer))
        fire(name, buffer)
        assert.are.equal(0, dispatches)
      end)

      it('clears every registered group in the scope', function()
        local buffer, name = scope_values()
        local first = register(first_group, name, buffer)
        local other = register(other_group, name, buffer)
        event.clear(buffer)

        assert.are.equal(0, count_id(first))
        assert.are.equal(0, count_id(other))
        assert.is_false(exists(first_group, buffer))
        assert.is_false(exists(other_group, buffer))
        fire(name, buffer)
        assert.are.equal(0, dispatches)
      end)

      it('removes obsolete events when replacing a registration', function()
        local buffer, old_name, new_name = scope_values()
        local calls = {}
        register(first_group, old_name, buffer, function()
          table.insert(calls, 'old')
        end)
        event.register(first_group, {
          {
            event = new_name,
            callback = function()
              table.insert(calls, 'new')
            end,
          },
        }, buffer)
        local current = commands(first_group, buffer)
        assert.are.equal(1, #current)
        assert.are.equal(new_name, current[1].event)

        fire(old_name, buffer)
        assert.are.same({}, calls)
        assert.are.equal(0, dispatches)
        fire(new_name, buffer)
        assert.are.same({ 'new' }, calls)
      end)

      it('replaces the same event without duplicate callbacks', function()
        local buffer, name = scope_values()
        local calls = {}
        register(first_group, name, buffer, function()
          table.insert(calls, 'old')
        end)
        register(first_group, name, buffer, function()
          table.insert(calls, 'new')
        end)

        fire(name, buffer)

        assert.are.same({ 'new' }, calls)
        assert.are.equal(1, dispatches)
        assert.are.equal(1, #commands(first_group, buffer))
      end)

      it('keeps other groups when one group is unregistered', function()
        local buffer, name = scope_values()
        local id = register(first_group, name, buffer)
        local calls = 0
        register(other_group, name, buffer, function()
          calls = calls + 1
        end)
        event.unregister(first_group, buffer)

        assert.are.equal(0, count_id(id))
        assert.is_true(exists(other_group, buffer))
        fire(name, buffer)
        assert.are.equal(1, calls)
        assert.are.equal(1, dispatches)
      end)

      it('can unregister and clear missing groups repeatedly', function()
        local buffer = scope_values()
        event.unregister(first_group, buffer)
        event.unregister(first_group, buffer)
        event.clear(buffer)
        event.clear(buffer)

        assert.is_false(exists(first_group, buffer))
      end)

      it('deletes a group with no event definitions', function()
        local buffer = scope_values()
        event.register(first_group, {}, buffer)
        assert.is_true(exists(first_group, buffer))

        event.unregister(first_group, buffer)

        assert.is_false(exists(first_group, buffer))
      end)
    end)
  end

  it('keeps global events when a buffer group is unregistered', function()
    local calls = {}
    register(first_group, 'BufEnter', 0, function()
      table.insert(calls, 'global')
    end)
    local id = register(first_group, 'BufEnter', buffers[1], function()
      table.insert(calls, 'buffer')
    end)

    event.unregister(first_group, buffers[1])

    assert.are.equal(0, count_id(id))
    assert.is_true(exists(first_group, 0))
    fire('BufEnter', buffers[1])
    assert.are.same({ 'global' }, calls)
  end)

  it('keeps global and other buffer events when clearing a buffer', function()
    local calls = {}
    register(first_group, 'BufEnter', 0, function()
      table.insert(calls, 'global')
    end)
    local id = register(first_group, 'BufEnter', buffers[1])
    register(first_group, 'BufEnter', buffers[2], function()
      table.insert(calls, 'other')
    end)

    event.clear(buffers[1])

    assert.are.equal(0, count_id(id))
    fire('BufEnter', buffers[1])
    assert.are.same({ 'global' }, calls)
    calls = {}
    fire('BufEnter', buffers[2])
    table.sort(calls)
    assert.are.same({ 'global', 'other' }, calls)
  end)

  it('dispatches multiple callbacks for one event exactly once', function()
    local calls = {}
    event.register(first_group, {
      {
        event = 'User',
        callback = function()
          table.insert(calls, 'first')
        end,
      },
      {
        event = 'User',
        callback = function()
          table.insert(calls, 'second')
        end,
      },
    }, 0)

    fire('User', 0)

    assert.are.same({ 'first', 'second' }, calls)
    assert.are.equal(1, dispatches)
    assert.are.equal(1, #commands(first_group, 0))
  end)
end)
