local core = require('vfiler/libs/core')
local fs = require('vfiler/libs/filesystem')

local Directory = require('vfiler/items/directory')
local File = require('vfiler/items/file')
local Item = require('vfiler/items/item')

local function describe_copy(item_class, item_type, copy_name)
  describe('copy', function()
    local root, source, destination, item
    local original_copy, original_stat

    local function content_path(path)
      return item_type == 'directory' and path .. '/content.txt' or path
    end

    local function create(path, content)
      if item_type == 'directory' then
        vim.fn.mkdir(path, 'p')
      end
      vim.fn.writefile({ content }, content_path(path))
    end

    before_each(function()
      original_copy = fs[copy_name]
      original_stat = fs.stat
      root = vim.fn.tempname()
      vim.fn.mkdir(root, 'p')
      source = core.path.join(root, 'source')
      destination = core.path.join(root, 'destination')
      create(source, 'SOURCE')
      item = item_class.new(fs.stat(source))
    end)

    after_each(function()
      fs[copy_name] = original_copy
      fs.stat = original_stat
      vim.fn.delete(root, 'rf')
    end)

    it('returns the copied item and keeps source contents', function()
      local copied = item:copy(destination)

      assert.is_not_nil(copied)
      assert.are.equal(fs.stat(destination).path, copied.path)
      assert.are.equal(item_type, copied.type)
      assert.are.same({ 'SOURCE' }, vim.fn.readfile(content_path(source)))
      assert.are.same(
        { 'SOURCE' },
        vim.fn.readfile(content_path(destination))
      )
    end)

    it('returns nil on failure with an existing destination', function()
      create(destination, 'DESTINATION')
      local flags = item_type == 'directory' and 'rf' or ''
      assert.are.equal(0, vim.fn.delete(source, flags))

      assert.is_nil(item:copy(destination))
      assert.are.same(
        { 'DESTINATION' },
        vim.fn.readfile(content_path(destination))
      )
    end)

    it('returns nil when a failed copy leaves partial data', function()
      fs[copy_name] = function()
        create(destination, 'PARTIAL')
        return false
      end

      assert.is_nil(item:copy(destination))
      assert.are.same({ 'SOURCE' }, vim.fn.readfile(content_path(source)))
      assert.are.same(
        { 'PARTIAL' },
        vim.fn.readfile(content_path(destination))
      )
    end)

    it('returns nil if stat fails after a successful copy', function()
      fs.stat = function(path)
        if path == destination then
          return nil
        end
        return original_stat(path)
      end

      assert.is_nil(item:copy(destination))
      assert.are.same({ 'SOURCE' }, vim.fn.readfile(content_path(source)))
      assert.are.same(
        { 'SOURCE' },
        vim.fn.readfile(content_path(destination))
      )
    end)
  end)
end

describe('item', function()
  local root = vim.fn.fnamemodify('./', ':p')

  describe('construction', function()
    it('initializes independent files with the base and file methods', function()
      local stat = {
        name = 'file.txt',
        path = core.path.join(root, 'file.txt'),
        type = 'file',
        size = 42,
        time = 1000000000,
        mode = 'rw-r--r--',
        link = false,
      }
      local first, second = File.new(stat), File.new(stat)

      first.selected = true
      first.level = 2

      assert.are.equal(Item.update, second.update)
      assert.are.equal(File.reload, second.reload)
      assert.are.equal(stat.path, second.path)
      assert.are.equal(stat.size, second.size)
      assert.are.equal(0, second.level)
      assert.is_false(second.selected)
      assert.is_nil(second.parent)
    end)

    it('keeps each directory child list independent', function()
      local stat = fs.stat(root)
      local first, second = Directory.new(stat), Directory.new(stat)
      local child = Directory.new(fs.stat(core.path.join(root, 'doc')))

      first:add(child)

      assert.are.equal(Item.delete, first.delete)
      assert.are.equal(Directory.open, first.open)
      assert.are.equal(first, child.parent)
      assert.are.equal(1, child.level)
      assert.are.equal(1, #first.children)
      assert.are.equal(child, first.children[1])
      assert.are.equal(child, first.child_directories[child.name])
      assert.is_nil(second.children)
      assert.is_nil(second.child_directories)
      assert.is_false(second.opened)
    end)
  end)

  describe('directory', function()
    describe_copy(Directory, 'directory', 'copy_directory')

    describe('recursive open', function()
      local temp, root, original_scandir, scans

      local function mkdir(path)
        assert.are.equal(1, vim.fn.mkdir(path, 'p'))
        return path
      end

      local function symlink(target, path)
        vim.fn.system({ 'ln', '-s', target, path })
        assert.are.equal(0, vim.v.shell_error)
      end

      local function directory(path)
        return Directory.new(fs.stat(path))
      end

      local function child(item, name)
        local result = item.child_directories[name]
        assert.is_not_nil(result)
        return result
      end

      before_each(function()
        original_scandir = fs.scandir
        temp = vim.fn.tempname()
        root = mkdir(core.path.join(temp, 'root'))
        scans = 0
        fs.scandir = function(...)
          scans = scans + 1
          assert(
            scans <= 32,
            'scan limit exceeded: possible directory cycle'
          )
          return original_scandir(...)
        end
      end)

      after_each(function()
        fs.scandir = original_scandir
        vim.fn.delete(temp, 'rf')
      end)

      it('opens ordinary nested directories', function()
        mkdir(root .. '/child/leaf')
        local item = directory(root)
        item:open(true)
        assert.is_true(item.opened)
        assert.is_true(child(item, 'child').opened)
        assert.is_true(child(child(item, 'child'), 'leaf').opened)
        assert.are.equal(3, scans)
      end)

      if not core.is_windows then
        it('leaves a self-referencing link closed', function()
          symlink(root, root .. '/loop')
          local item = directory(root)
          item:open(true)
          assert.is_true(item.opened)
          assert.is_true(child(item, 'loop').link)
          assert.is_false(child(item, 'loop').opened)
          assert.are.equal(1, scans)
        end)

        it('stops both links pointing back to the root', function()
          symlink(root, root .. '/loop1')
          symlink(root, root .. '/loop2')
          local item = directory(root)
          item:open(true)
          assert.is_false(child(item, 'loop1').opened)
          assert.is_false(child(item, 'loop2').opened)
          assert.are.equal(1, scans)
        end)

        it('stops a link to an ancestor directory', function()
          mkdir(root .. '/child')
          symlink(root, root .. '/child/up')
          local item = directory(root)
          item:open(true)
          assert.is_true(child(item, 'child').opened)
          assert.is_false(child(child(item, 'child'), 'up').opened)
          assert.are.equal(2, scans)
        end)

        it('opens an ordinary link to another directory', function()
          local target = mkdir(core.path.join(temp, 'target'))
          mkdir(target .. '/leaf')
          symlink(target, root .. '/alias')
          local item = directory(root)
          item:open(true)
          assert.is_true(child(item, 'alias').opened)
          assert.is_true(child(child(item, 'alias'), 'leaf').opened)
          assert.are.equal(3, scans)
        end)

        it('opens sibling links to the same target separately', function()
          mkdir(root .. '/target/leaf')
          symlink(root .. '/target', root .. '/left')
          symlink(root .. '/target', root .. '/right')
          local item = directory(root)
          item:open(true)
          for _, name in ipairs({ 'target', 'left', 'right' }) do
            assert.is_true(child(item, name).opened)
            assert.is_true(child(child(item, name), 'leaf').opened)
          end
          assert.are.equal(7, scans)
        end)

        it('allows a skipped cyclic link to be opened manually', function()
          symlink(root, root .. '/loop')
          local item = directory(root)
          item:open(true)
          local loop = child(item, 'loop')
          assert.is_false(loop.opened)
          loop:open()
          assert.is_true(loop.opened)
          assert.is_false(child(loop, 'loop').opened)
          assert.are.equal(2, scans)
        end)

        it('preserves manually opened links on reload', function()
          symlink(root, root .. '/loop')
          local item = directory(root)
          item:open()
          child(item, 'loop'):open()
          item:open()
          assert.is_true(child(item, 'loop').opened)
          assert.is_false(child(child(item, 'loop'), 'loop').opened)
          assert.are.equal(4, scans)
        end)

        it('resets ancestor tracking for each recursive open', function()
          symlink(root, root .. '/loop')
          local item = directory(root)
          item:open(true)
          item:open(true)
          assert.is_true(item.opened)
          assert.is_false(child(item, 'loop').opened)
          assert.are.equal(2, scans)
        end)

        it('detects cycles when starting from a link', function()
          symlink(root, root .. '/loop')
          local start = core.path.join(temp, 'start')
          symlink(root, start)
          local item = directory(start)
          item:open(true)
          assert.is_true(item.opened)
          assert.is_false(child(item, 'loop').opened)
          assert.are.equal(1, scans)
        end)
      end
    end)

    it('create and delete', function()
      local dirpath = core.path.join(root, 'foo')
      local dir = Directory.create(dirpath)
      assert.is_not_nil(dir)
      assert.is_true(core.path.exists(dirpath))

      local result = dir:delete()
      assert.is_true(result)
      assert.is_false(core.path.exists(dirpath))
    end)

    it('update', function()
      local stat = fs.stat(root)
      local dir = Directory.new(stat)
      assert.is_not_nil(dir)
      dir:update()
    end)
  end)

  describe('file', function()
    describe_copy(File, 'file', 'copy_file')

    it('create and delete', function()
      -- TODO:
      --local filepath = core.path.join(root, 'foo')
      --local file = File.create(filepath)
      --assert.is_not_nil(file)
      --assert.is_true(core.path.exists(filepath))

      --local result = file:delete()
      --assert.is_true(result)
      --assert.is_false(core.path.exists(filepath))
    end)

    it('update', function()
      local path = core.path.join(root, 'README.md')
      local stat = fs.stat(path)
      local file = File.new(stat)
      assert.is_not_nil(file)

      local expected = {
        name = file.name,
        path = file.path,
        size = file.size,
        time = file.time,
        type = file.type,
        mode = file.mode,
        link = file.link,
      }
      file:update()
      for prop, value in pairs(expected) do
        assert.equal(value, file[prop])
      end
    end)
  end)
end)
