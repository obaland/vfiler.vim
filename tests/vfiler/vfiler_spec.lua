local u = require('tests/utility')
local Buffer = require('vfiler/buffer')

describe('vfiler', function()
  describe('Start', function()
    it('simple', function()
      local vfiler = u.vfiler.start()
      local bufnr = vfiler._buffer.number
      assert.equal(bufnr, vim.fn.bufnr())
      assert.is_true(Buffer.is_vfiler_buffer(bufnr))
      vfiler:quit(true)
    end)

    local configs = {
      options = u.vfiler.generate_options(),
    }
    it('with options', function()
      local vfiler = u.vfiler.start(configs)
      local bufnr = vfiler._buffer.number
      assert.equal(bufnr, vim.fn.bufnr())
      assert.is_true(Buffer.is_vfiler_buffer(bufnr))
      vfiler:quit(true)
    end)

    local args = u.convert_command_options(configs.options)
    it('from command args ', function()
      local vfiler = u.vfiler.start_command(args)
      local bufnr = vfiler._buffer.number
      assert.equal(bufnr, vim.fn.bufnr())
      assert.is_true(Buffer.is_vfiler_buffer(bufnr))
      vfiler:quit(true)
    end)
  end)

  describe('Start with "new" option', function()
    it('name option "foo"', function()
      local configs = {
        options = {
          name = 'foo',
          new = true,
        },
      }
      local vfiler1 = u.vfiler.start(configs)
      assert.equal('vfiler:foo', vim.fn.bufname())

      local vfiler2 = u.vfiler.start(configs)
      assert.equal('vfiler:foo-1', vim.fn.bufname())

      vfiler2:quit(true)
      vfiler1:quit(true)
    end)

    it('name option "vfiler"', function()
      local configs = {
        options = {
          name = 'vfiler',
          new = true,
        },
      }
      local vfiler1 = u.vfiler.start(configs)
      assert.equal('vfiler:vfiler', vim.fn.bufname())

      local vfiler2 = u.vfiler.start(configs)
      assert.equal('vfiler:vfiler-1', vim.fn.bufname())

      vfiler2:quit(true)
      vfiler1:quit(true)
    end)
  end)

  describe('Start with "new" option', function()
    it('call the "status" interface', function()
      local vfiler = u.vfiler.start(configs)
      assert.is_not_nil(vfiler)

      local status = vfiler:status()
      assert.equal('table', type(status))

      assert.is_not_nil(status.bufnr)
      assert.is_not_nil(status.root)
      assert.is_not_nil(status.num_items)
      assert.is_not_nil(status.current_item)
      assert.equal('table', type(status.current_item))

      local current_item = status.current_item
      assert.is_not_nil(current_item.number)
      assert.is_not_nil(current_item.name)
      assert.is_not_nil(current_item.path)
      assert.is_not_nil(current_item.size)
      assert.is_not_nil(current_item.time)
      assert.is_not_nil(current_item.type)
      assert.is_not_nil(current_item.mode)
      assert.is_not_nil(current_item.link)

      vfiler:quit()
    end)
  end)
end)
