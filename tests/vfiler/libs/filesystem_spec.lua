local core = require('vfiler/libs/core')
local fs = require('vfiler/libs/filesystem')

describe('filesystem $shell:' .. vim.o.shell, function()
  local paths = vim.fn.glob('./*', 1, 1)
  describe('stat', function()
    for _, path in ipairs(paths) do
      it(path, function()
        local stat = fs.stat(path)
        assert.is_not_nil(stat)
        assert.is_equal(core.path.name(path), stat.name)
        assert.is_equal(core.path.normalize(path), stat.path)
        assert.is_equal(vim.fn.getfperm(path), stat.mode)
        assert.is_equal(vim.fn.getftime(path), stat.time)
        -- TODO: different for each platform
        --assert.is_equal(vim.fn.getfsize(path), stat.size)

        if core.path.is_directory(path) then
          assert.is_equal('directory', stat.type)
        else
          assert.is_equal('file', stat.type)
        end

        local resolve = vim.fn.resolve(path)
        assert.is_equal(resolve ~= path, stat.link)
      end)
    end
  end)

  -- TODO: ubuntu
  if not (core.is_windows or core.is_mac) then
    return
  end

  describe('create file', function()
    local filepaths = {
      'testfile',
      '#testfile',
      'test#file',
      '%testfile',
      'test%file',
      '#test%file',
      '%test#file',
    }

    for _, path in ipairs(filepaths) do
      it(path, function()
        local result = fs.create_file(path)
        assert.is_true(result)
        assert.is_true(core.path.filereadable(path))

        result = fs.delete(path)
        assert.is_true(result)
        assert.is_false(core.path.filereadable(path))
      end)
    end
  end)

  describe('create directory', function()
    local dirpaths = {
      'testdir',
      '#testdir',
      'test#dir',
      '%testdir',
      'test%dir',
      '#test%dir',
      '%test#dir',
    }
    for _, path in ipairs(dirpaths) do
      it(path, function()
        local result = fs.create_directory(path)
        assert.is_true(result)
        assert.is_true(core.path.is_directory(path))

        result = fs.delete(path)
        assert.is_true(result)
        assert.is_false(core.path.is_directory(path))
      end)
    end
  end)

  describe('copy file', function()
    local destdir = 'testdir'
    local filepaths = {
      'testfile',
      '#testfile',
      'test#file',
      '%testfile',
      'test%file',
      '#test%file',
      '%test#file',
    }
    local result
    -- Setup
    if not core.path.is_directory(destdir) then
      result = fs.create_directory(destdir)
      assert.is_true(result)
      assert.is_true(core.path.is_directory(destdir))
    end

    for _, path in ipairs(filepaths) do
      it(path .. ' -> ' .. destdir, function()
        result = fs.create_file(path)
        assert.is_true(result)

        local destpath = core.path.join(destdir, path)

        result = fs.copy_file(path, destpath)
        assert.is_true(result)
        assert.is_true(core.path.filereadable(destpath))
        assert.is_true(core.path.filereadable(path))

        result = fs.delete(path)
        assert.is_true(result)
        assert.is_false(core.path.filereadable(path))
      end)
    end

    -- Teardown
    if core.path.exists(destdir) then
      result = fs.delete(destdir)
      assert.is_true(result)
      assert.is_false(core.path.is_directory(destdir))
    end
  end)

  describe('move file', function()
    local destdir = 'testdir'
    local filepaths = {
      'testfile',
      '#testfile',
      'test#file',
      '%testfile',
      'test%file',
      '#test%file',
      '%test#file',
    }

    local result
    -- Setup
    if not core.path.is_directory(destdir) then
      result = fs.create_directory(destdir)
      assert.is_true(result)
      assert.is_true(core.path.is_directory(destdir))
    end

    for _, path in ipairs(filepaths) do
      it(path .. ' -> ' .. destdir, function()
        result = fs.create_file(path)
        assert.is_true(result)

        local destpath = core.path.join(destdir, path)

        result = fs.move(path, destpath)
        assert.is_true(result)
        assert.is_true(core.path.filereadable(destpath))
        assert.is_false(core.path.filereadable(path))
      end)
    end

    -- Teardown
    if core.path.exists(destdir) then
      result = fs.delete(destdir)
      assert.is_true(result)
      assert.is_false(core.path.is_directory(destdir))
    end
  end)

  describe('copy directory', function()
    local srcdir = 'srcdir'
    local destdir = 'destdir'
    local filepaths = {
      'testfile',
      '#testfile',
      'test#file',
      '%testfile',
      'test%file',
      '#test%file',
      '%test#file',
    }

    local result
    -- Setup
    if not core.path.is_directory(srcdir) then
      result = fs.create_directory(srcdir)
      assert.is_true(result)
      assert.is_true(core.path.is_directory(srcdir))
    end

    if not core.path.is_directory(destdir) then
      result = fs.create_directory(destdir)
      assert.is_true(result)
      assert.is_true(core.path.is_directory(destdir))
    end

    for _, path in ipairs(filepaths) do
      local filepath = core.path.join(srcdir, path)
      result = fs.create_file(filepath)
      assert.is_true(result)
      assert.is_true(core.path.filereadable(filepath))
    end

    it(srcdir .. ' -> ' .. destdir, function()
      local destpath = core.path.join(destdir, srcdir)
      result = fs.copy_directory(srcdir, destpath)
      assert.is_true(result)
      assert.is_true(core.path.is_directory(destpath))

      for _, path in ipairs(filepaths) do
        local srcpath = core.path.join(srcdir, path)
        assert.is_true(core.path.filereadable(srcpath))
        local copiedpath = core.path.join(destpath, path)
        assert.is_true(core.path.filereadable(copiedpath))
      end
    end)

    -- Teardown
    if core.path.exists(srcdir) then
      result = fs.delete(srcdir)
      assert.is_true(result)
      assert.is_false(core.path.is_directory(srcdir))
    end

    if core.path.exists(destdir) then
      result = fs.delete(destdir)
      assert.is_true(result)
      assert.is_false(core.path.is_directory(destdir))
    end
  end)

  describe('move directory', function()
    local srcdir = 'srcdir'
    local destdir = 'destdir'
    local filepaths = {
      'testfile',
      '#testfile',
      'test#file',
      '%testfile',
      'test%file',
      '#test%file',
      '%test#file',
    }

    local result
    -- Setup
    if not core.path.is_directory(srcdir) then
      result = fs.create_directory(srcdir)
      assert.is_true(result)
      assert.is_true(core.path.is_directory(srcdir))
    end
    if not core.path.is_directory(destdir) then
      result = fs.create_directory(destdir)
      assert.is_true(result)
      assert.is_true(core.path.is_directory(destdir))
    end

    for _, path in ipairs(filepaths) do
      local filepath = core.path.join(srcdir, path)
      it('create:' .. filepath, function()
        result = fs.create_file(filepath)
        assert.is_true(result)
        assert.is_true(core.path.filereadable(filepath))
      end)
    end

    it(srcdir .. ' -> ' .. destdir, function()
      local destpath = core.path.join(destdir, srcdir)
      result = fs.move(srcdir, destpath)
      assert.is_true(result)
      assert.is_true(core.path.is_directory(destpath))

      for _, path in ipairs(filepaths) do
        local srcpath = core.path.join(srcdir, path)
        assert.is_false(core.path.filereadable(srcpath))
        local movedpath = core.path.join(destpath, path)
        assert.is_true(core.path.filereadable(movedpath))
      end
    end)

    --Teardown
    if core.path.exists(srcdir) then
      result = fs.delete(srcdir)
      assert.is_true(result)
      assert.is_false(core.path.is_directory(srcdir))
    end
    if core.path.exists(destdir) then
      result = fs.delete(destdir)
      assert.is_true(result)
      assert.is_false(core.path.is_directory(destdir))
    end
  end)
end)
