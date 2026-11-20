local core = require('vfiler/libs/core')
local fs = require('vfiler/libs/filesystem')
local Directory = require('vfiler/items/directory')
local Session = require('vfiler/context/session')
local VFiler = require('vfiler/vfiler')

describe('session restoration after item type changes', function()
  local temp, root, filer

  local function child(item, name)
    for _, value in ipairs(item.children or {}) do
      if value.name == name then
        return value
      end
    end
    return nil
  end

  local function open_root()
    local item = Directory.new(fs.stat(root))
    item:open()
    return item
  end

  local function save_opened(session)
    local item = open_root()
    child(item, 'sub'):open()
    child(item, 'other'):open()
    child(item, 'sub').selected = true
    session:save(item, child(item, 'sub').path)
    return item
  end

  local function replace_subdirectory()
    assert.are.equal(0, vim.fn.delete(root .. '/sub', 'rf'))
    assert.are.equal(0, vim.fn.writefile({ 'REPLACEMENT' }, root .. '/sub'))
  end

  before_each(function()
    filer = nil
    temp = vim.fn.tempname()
    root = core.path.join(temp, 'root')
    vim.fn.mkdir(root .. '/sub/leaf', 'p')
    vim.fn.mkdir(root .. '/other', 'p')
    vim.fn.writefile({ 'FILE' }, root .. '/file.txt')
    root = core.path.normalize(root)
  end)

  after_each(function()
    if filer then
      filer:wipeout()
    end
    vim.fn.delete(temp, 'rf')
  end)

  for _, mode in ipairs({ 'buffer', 'share' }) do
    describe(mode, function()
      it('restores expansion and selection for unchanged items', function()
        local session = Session.new(mode)
        local item = save_opened(session)
        child(child(item, 'sub'), 'leaf'):open()
        child(item, 'file.txt').selected = true
        local cursor = child(item, 'file.txt').path
        session:save(item, cursor)
        local restored = open_root()

        assert.are.equal(cursor, session:load(restored))
        assert.is_true(child(restored, 'sub').opened)
        assert.is_true(child(child(restored, 'sub'), 'leaf').opened)
        assert.is_true(child(restored, 'other').opened)
        assert.is_true(child(restored, 'file.txt').selected)
      end)

      it('skips expansion when a directory becomes a file', function()
        local session = Session.new(mode)
        save_opened(session)
        replace_subdirectory()
        local restored = open_root()

        session:load(restored)

        assert.are.equal('file', child(restored, 'sub').type)
        assert.is_true(child(restored, 'sub').selected)
        assert.is_true(child(restored, 'other').opened)
        assert.are.same(
          { 'REPLACEMENT' },
          vim.fn.readfile(root .. '/sub')
        )
      end)

      it('handles a nested directory becoming a file', function()
        local session = Session.new(mode)
        local item = save_opened(session)
        local leaf = child(child(item, 'sub'), 'leaf')
        leaf:open()
        leaf.selected = true
        session:save(item, leaf.path)
        assert.are.equal(0, vim.fn.delete(root .. '/sub/leaf', 'd'))
        vim.fn.writefile({ 'REPLACEMENT' }, root .. '/sub/leaf')
        local restored = open_root()

        session:load(restored)

        local restored_sub = child(restored, 'sub')
        assert.is_true(restored_sub.opened)
        assert.are.equal('file', child(restored_sub, 'leaf').type)
        assert.is_true(child(restored_sub, 'leaf').selected)
        assert.is_true(child(restored, 'other').opened)
      end)

      it('restores other items after a directory is deleted', function()
        local session = Session.new(mode)
        save_opened(session)
        assert.are.equal(0, vim.fn.delete(root .. '/sub', 'rf'))
        local restored = open_root()

        session:load(restored)

        assert.is_nil(child(restored, 'sub'))
        assert.is_true(child(restored, 'other').opened)
      end)

      it('keeps a replacement directory closed', function()
        local session = Session.new(mode)
        local item = open_root()
        child(item, 'file.txt').selected = true
        session:save(item, child(item, 'file.txt').path)
        vim.fn.delete(root .. '/file.txt')
        vim.fn.mkdir(root .. '/file.txt')
        local restored = open_root()

        session:load(restored)

        local replaced = child(restored, 'file.txt')
        assert.are.equal('directory', replaced.type)
        assert.is_false(replaced.opened)
        assert.is_true(replaced.selected)
      end)

      it('restores a copied session after a type change', function()
        local session = Session.new(mode)
        save_opened(session)
        local copied = session:copy()
        replace_subdirectory()
        local restored = open_root()

        copied:load(restored)

        assert.are.equal('file', child(restored, 'sub').type)
        assert.is_true(child(restored, 'other').opened)
      end)

      it('reloads after an opened directory becomes a file', function()
        assert.is_true(require('vfiler').start(root, {
          options = {
            new = true,
            header = true,
            columns = 'name',
            session = mode,
            git = { enabled = false },
          },
        }))
        filer = VFiler.get(vim.fn.bufnr())
        local context, view = filer._context, filer._view
        local sub = child(context.root, 'sub')
        sub:open()
        sub.selected = true
        view:draw(context)
        view:move_cursor(sub.path)
        replace_subdirectory()

        filer:do_action(require('vfiler/actions/buffer').reload_all_dir)

        local restored = child(context.root, 'sub')
        assert.are.equal('file', restored.type)
        assert.is_true(restored.selected)
        assert.are.equal(root .. 'sub', restored.path)
        assert.are.equal('file', view:itemof(restored.path).type)
      end)
    end)
  end
end)
