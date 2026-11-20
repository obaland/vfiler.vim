local core = require('vfiler/libs/core')
local fs = require('vfiler/libs/filesystem')

local Directory = require('vfiler/items/directory')
local File = require('vfiler/items/file')

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

  describe('directory', function()
    describe_copy(Directory, 'directory', 'copy_directory')

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
