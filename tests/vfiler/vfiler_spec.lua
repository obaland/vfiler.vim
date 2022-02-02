local u = require('tests/utility')
local Buffer = require('vfiler/buffer')

describe('vfiler', function()
  describe('Start', function()
    it('simple', function()
      local vfiler = u.vfiler.start()
      local bufnr = vfiler._buffer.number
      assert.equal(bufnr, vim.fn.bufnr())
      assert.is_true(Buffer.is_vfiler_buffer(bufnr))
    end)

    --local configs = {
    --  options = u.vfiler.generate_options(),
    --}
    --it('with options: ' .. vim.inspect(configs), function()
    --  local vfiler = u.vfiler.start(configs)
    --  local bufnr = vfiler._buffer.number
    --  assert.equal(bufnr, vim.fn.bufnr())
    --  assert.is_true(Buffer.is_vfiler_buffer(bufnr))
    --end)

    --local args = u.convert_command_options(configs.options)
    --it('from command args: ' .. args, function()
    --  local vfiler = u.vfiler.start_command(args)
    --  local bufnr = vfiler._buffer.number
    --  assert.equal(bufnr, vim.fn.bufnr())
    --  assert.is_true(Buffer.is_vfiler_buffer(bufnr))
    --end)
  end)

  describe('Start with "new" option', function()
    it('name option "foo"', function()
      local configs = {
        options = {
          name = 'foo',
          new = true
        },
      }
      u.vfiler.start(configs)
      assert.equal('vfiler:foo', vim.fn.bufname())

      u.vfiler.start(configs)
      assert.equal('vfiler:foo-1', vim.fn.bufname())
    end)

    it('name option "vfiler"', function()
      local configs = {
        options = {
          name = 'vfiler',
          new = true
        },
      }
      u.vfiler.start(configs)
      assert.equal('vfiler:vfiler', vim.fn.bufname())

      u.vfiler.start(configs)
      assert.equal('vfiler:vfiler-1', vim.fn.bufname())
    end)
  end)
end)
