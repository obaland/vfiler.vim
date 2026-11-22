local core = require('vfiler/libs/core')
local u = require('tests/helper/utilities')
local Buffer = require('vfiler/buffer')
local VFiler = require('vfiler/vfiler')

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

  describe('start at a nested path', function()
    local dir, filer, parent, child, file

    before_each(function()
      dir = core.path.normalize(vim.fn.tempname())
      parent = dir .. '/parent/'
      child = parent .. 'child/'
      file = child .. 'target.txt'
      assert.equal(1, vim.fn.mkdir(child, 'p'))
      assert.equal(0, vim.fn.writefile({}, dir .. '/sibling.txt'))
      assert.equal(0, vim.fn.writefile({}, parent .. 'sibling.txt'))
      assert.equal(0, vim.fn.writefile({}, child .. 'sibling.txt'))
      assert.equal(0, vim.fn.writefile({}, file))
      assert.is_true(require('vfiler').start(dir, {
        options = {
          columns = 'name',
          layout = 'right',
          new = true,
          session = 'none',
        },
      }))
      filer = VFiler.get(vim.fn.bufnr())
    end)

    after_each(function()
      if filer then
        filer:wipeout()
        filer = nil
      end
      vim.fn.delete(dir, 'rf')
    end)

    it('opens the ancestor directories and selects the target file', function()
      filer:start(dir, file)
      local view = filer._view
      assert.is_true(view:itemof(parent).opened)
      assert.is_true(view:itemof(child).opened)
      assert.equal(file, view:get_item().path)
    end)

    it('selects a target directory without expanding it', function()
      filer:start(dir, child)
      local view = filer._view
      assert.is_true(view:itemof(parent).opened)
      assert.equal(child, view:get_item().path)
      assert.is_false(view:get_item().opened)
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

  describe('Interface', function()
    it('call the "status" interface', function()
      local vfiler = u.vfiler.start()
      assert.is_not_nil(vfiler)

      local status = vfiler:status()
      assert.equal('table', type(status))

      assert.is_not_nil(status.bufnr)
      assert.is_not_nil(status.root)
      assert.is_not_nil(status.num_items)
      assert.equal('table', type(status.current_item))
      assert.equal('table', type(status.options))

      local current_item = status.current_item
      assert.is_not_nil(current_item.number)
      assert.is_not_nil(current_item.name)
      assert.is_not_nil(current_item.path)
      assert.is_not_nil(current_item.size)
      assert.is_not_nil(current_item.time)
      assert.is_not_nil(current_item.type)
      assert.is_not_nil(current_item.mode)
      assert.is_not_nil(current_item.link)

      local options = status.options
      assert.is_not_nil(options.width)
      assert.is_not_nil(options.height)

      vfiler:quit()
    end)
  end)

  describe('cleanup', function()
    local root, created

    local function start(new)
      assert.is_true(require('vfiler').start(root, {
        options = {
          name = 'cleanup-test',
          new = new or false,
          layout = 'none',
          columns = 'name',
          session = 'none',
          git = { enabled = false },
        },
      }))
      local filer = VFiler.get(vim.fn.bufnr())
      assert.is_not_nil(filer)
      local known = false
      for _, object in ipairs(created) do
        known = known or object == filer
      end
      if not known then
        table.insert(created, filer)
      end
      return filer, filer._buffer.number
    end

    before_each(function()
      created = {}
      root = vim.fn.tempname()
      vim.fn.mkdir(root, 'p')
    end)

    after_each(function()
      for i = #created, 1, -1 do
        created[i]:wipeout()
      end
      vim.fn.delete(root, 'rf')
    end)

    it('retains a loaded visible filer', function()
      local filer, bufnr = start()
      VFiler.cleanup()
      assert.is_true(VFiler.exists(bufnr))
      assert.are.equal(filer, VFiler.get(bufnr))
      assert.are.equal(1, vim.fn.bufloaded(bufnr))
    end)

    it('retains and reuses a loaded hidden filer', function()
      local filer, bufnr = start()
      vim.cmd('enew')
      assert.are.equal(-1, vim.fn.bufwinid(bufnr))
      assert.are.equal(1, vim.fn.bufloaded(bufnr))
      VFiler.cleanup()
      assert.are.equal(filer, VFiler.get(bufnr))
      local reopened, reopened_bufnr = start()
      assert.are.equal(filer, reopened)
      assert.are.equal(bufnr, reopened_bufnr)
    end)

    it('removes wiped buffers without wiping them again', function()
      local _, bufnr = start()
      vim.cmd('bwipeout! ' .. bufnr)
      assert.are.equal(0, vim.fn.bufexists(bufnr))
      VFiler.cleanup()
      assert.is_false(VFiler.exists(bufnr))
      assert.is_nil(VFiler.get(bufnr))
    end)

    it('wipes unloaded buffers and removes their entries', function()
      local _, bufnr = start()
      vim.cmd('enew')
      vim.cmd('bunload! ' .. bufnr)
      assert.are.equal(1, vim.fn.bufexists(bufnr))
      assert.are.equal(0, vim.fn.bufloaded(bufnr))
      VFiler.cleanup()
      assert.are.equal(0, vim.fn.bufexists(bufnr))
      assert.is_false(VFiler.exists(bufnr))
      assert.is_nil(VFiler.get(bufnr))
    end)

    it('starts again after an external buffer wipe', function()
      local old, bufnr = start()
      vim.cmd('bwipeout! ' .. bufnr)
      local restarted, new_bufnr = start()
      assert.is_false(VFiler.exists(bufnr))
      assert.is_not.equal(old, restarted)
      assert.is_not.equal(bufnr, new_bufnr)
      assert.are.equal(restarted, VFiler.get(new_bufnr))
      assert.are.equal(1, vim.fn.bufloaded(new_bufnr))
    end)

    it('removes stale entries while preserving a valid filer', function()
      local _, stale_bufnr = start(true)
      local kept, kept_bufnr = start(true)
      vim.cmd('bwipeout! ' .. stale_bufnr)
      VFiler.cleanup()
      assert.is_false(VFiler.exists(stale_bufnr))
      assert.are.equal(kept, VFiler.get(kept_bufnr))
      assert.are.equal(1, vim.fn.bufloaded(kept_bufnr))
    end)
  end)
end)
