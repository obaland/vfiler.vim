local a = require('vfiler/actions/buffer')
local core = require('vfiler/libs/core')
local u = require('tests/helper/utilities')
local VFiler = require('vfiler/vfiler')

local configs = {
  options = u.vfiler.generate_options(),
}

describe('buffer actions', function()
  describe('Control buffer', function()
    local vfiler = u.vfiler.start(configs)

    it(u.vfiler.desc('redraw', vfiler), function()
      vfiler:do_action(a.redraw)
    end)

    it(u.vfiler.desc('reload', vfiler), function()
      vfiler:do_action(a.reload)
    end)

    it(u.vfiler.desc('switch_to_filer', vfiler), function()
      vfiler:do_action(a.switch_to_filer)
      vfiler:do_action(a.sync_with_current_filer)
      local newfiler = VFiler.get(vim.fn.bufnr())
      newfiler:quit(true)
    end)
  end)

  describe('reload an expanded tree', function()
    local filer, view, root, branch, leaf
    local initial_time = 1000000000
    local changed_time = initial_time + 10

    local function set_time(path, time)
      assert(vim.loop.fs_utime(path, time, time))
    end

    local function write_file(path, text)
      assert.are.equal(0, vim.fn.writefile({ text }, path, 'b'))
    end

    before_each(function()
      filer = nil
      root = core.path.normalize(vim.fn.tempname())
      branch = root .. '/branch'
      leaf = branch .. '/leaf'
      assert.are.equal(1, vim.fn.mkdir(leaf, 'p'))
      write_file(root .. '/selected.txt', 'selected')
      write_file(leaf .. '/existing.txt', 'old')
      for _, path in ipairs({ root, branch, leaf }) do
        set_time(path, initial_time)
      end

      assert.is_true(require('vfiler').start(root, {
        options = {
          columns = 'name',
          layout = 'right',
          new = true,
          session = 'buffer',
        },
      }))
      filer = VFiler.get(vim.fn.bufnr())
      view = filer._view
      filer._context:open_tree(leaf):open()
      filer:draw()
      view:itemof(root .. '/selected.txt').selected = true
    end)

    after_each(function()
      if filer then
        filer:wipeout()
      end
      vim.fn.delete(root, 'rf')
    end)

    it('shows changes in an expanded parent and child after reload', function()
      write_file(branch .. '/new.txt', 'parent')
      write_file(leaf .. '/new.txt', 'child')
      assert.are.equal(0, vim.fn.delete(leaf .. '/existing.txt'))
      set_time(branch, changed_time)
      set_time(leaf, changed_time)

      filer:do_action(a.reload)

      assert.is_true(view:itemof(branch .. '/').opened)
      assert.is_true(view:itemof(leaf .. '/').opened)
      assert.is_not_nil(view:itemof(branch .. '/new.txt'))
      assert.is_not_nil(view:itemof(leaf .. '/new.txt'))
      assert.is_nil(view:itemof(leaf .. '/existing.txt'))
      assert.is_true(view:itemof(root .. '/selected.txt').selected)
    end)

    it('finds a changed child beneath an unchanged parent', function()
      write_file(leaf .. '/new.txt', 'child')
      set_time(leaf, changed_time)

      filer:do_action(a.reload)

      assert.is_true(view:itemof(branch .. '/').opened)
      assert.is_not_nil(view:itemof(leaf .. '/new.txt'))
    end)

    it('refreshes file metadata in the subtree of a changed parent', function()
      local path = leaf .. '/existing.txt'
      write_file(path, 'updated')
      write_file(branch .. '/new.txt', 'parent')
      set_time(branch, changed_time)
      set_time(leaf, initial_time)

      filer:do_action(a.reload)

      assert.are.equal(7, view:itemof(path).size)
    end)

    it('refreshes file metadata on a full reload', function()
      local path = leaf .. '/existing.txt'
      write_file(path, 'updated')
      set_time(leaf, initial_time)

      filer:do_action(a.reload_all_dir)

      assert.are.equal(7, view:itemof(path).size)
      assert.is_true(view:itemof(leaf .. '/').opened)
      assert.is_true(view:itemof(root .. '/selected.txt').selected)
    end)
  end)
end)
