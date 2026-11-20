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
        assert.is_equal(vim.fn.getfsize(path), stat.size)

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

  if not core.is_windows then
    describe('permission modes', function()
      local root, filepath, directory

      local modes = {
        { name = '000', value = '---------' },
        { name = '001', value = '--------x' },
        { name = '007', value = '------rwx' },
        { name = '010', value = '-----x---' },
        { name = '040', value = '---r-----' },
        { name = '077', value = '---rwxrwx' },
        { name = '100', value = '--x------' },
        { name = '600', value = 'rw-------' },
        { name = '644', value = 'rw-r--r--' },
        { name = '755', value = 'rwxr-xr-x' },
        { name = '777', value = 'rwxrwxrwx' },
      }

      before_each(function()
        root = vim.fn.tempname()
        filepath = core.path.join(root, 'file')
        directory = core.path.join(root, 'directory')
        vim.fn.mkdir(root, 'p')
        vim.fn.mkdir(directory)
        vim.fn.writefile({ 'CONTENT' }, filepath)
      end)

      after_each(function()
        -- Restore owner access before deleting restricted directories.
        vim.fn.setfperm(filepath, 'rw-------')
        vim.fn.setfperm(directory, 'rwx------')
        vim.fn.delete(root, 'rf')
      end)

      local function assert_mode(stat, expected)
        assert.is_not_nil(stat)
        assert.are.equal(expected, stat.mode)
        assert.are.equal(9, #stat.mode)
      end

      for _, mode in ipairs(modes) do
        it('reads nine-character file mode ' .. mode.name, function()
          assert.are.equal(1, vim.fn.setfperm(filepath, mode.value))

          assert_mode(fs.stat(filepath), mode.value)
        end)

        it('reads nine-character directory mode ' .. mode.name, function()
          assert.are.equal(1, vim.fn.setfperm(directory, mode.value))

          assert_mode(fs.stat(directory), mode.value)
        end)

        it('scans file and directory mode ' .. mode.name, function()
          assert.are.equal(1, vim.fn.setfperm(filepath, mode.value))
          assert.are.equal(1, vim.fn.setfperm(directory, mode.value))
          local entries = {}

          fs.scandir(root, function(stat)
            entries[stat.name] = stat
          end)

          assert_mode(entries.file, mode.value)
          assert_mode(entries.directory, mode.value)
        end)
      end

      it('keeps other and owner execute permissions separate', function()
        assert.are.equal(1, vim.fn.setfperm(filepath, '--------x'))
        local stat = fs.stat(filepath)
        local column = require('vfiler/columns/mode').new()

        local text = column:to_text({
          name = 'file',
          type = stat.type,
          mode = stat.mode,
          link = stat.link,
        }, 4)

        assert.are.equal('----', text.string)
        assert.are.equal('file', text.syntax)
        assert.are.equal(4, text.width)
      end)
    end)
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

        result = fs.delete_file(path)
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

        result = fs.delete_directory(path)
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

        result = fs.delete_file(path)
        assert.is_true(result)
        assert.is_false(core.path.filereadable(path))
      end)
    end

    -- Teardown
    if core.path.exists(destdir) then
      result = fs.delete_directory(destdir)
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
      result = fs.delete_directory(destdir)
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
      result = fs.delete_directory(srcdir)
      assert.is_true(result)
      assert.is_false(core.path.is_directory(srcdir))
    end

    if core.path.exists(destdir) then
      result = fs.delete_directory(destdir)
      assert.is_true(result)
      assert.is_false(core.path.is_directory(destdir))
    end

    describe('contents', function()
      local root, source, destination

      local function write(path, content)
        assert.are.equal(0, vim.fn.writefile({ content }, path))
      end

      before_each(function()
        root = vim.fn.tempname()
        vim.fn.mkdir(root, 'p')
        source = core.path.join(root, 'source')
        destination = core.path.join(root, 'destination')
        vim.fn.mkdir(source, 'p')
        write(source .. '/shared.txt', 'NEW')
        write(source .. '/added.txt', 'ADDED')
        write(source .. '/.hidden', 'HIDDEN')
        vim.fn.mkdir(source .. '/empty', 'p')
      end)

      after_each(function()
        vim.fn.delete(root, 'rf')
      end)

      local function assert_contents()
        assert.are.same(
          { 'NEW' },
          vim.fn.readfile(destination .. '/shared.txt')
        )
        assert.are.same(
          { 'ADDED' },
          vim.fn.readfile(destination .. '/added.txt')
        )
        assert.are.same(
          { 'HIDDEN' },
          vim.fn.readfile(destination .. '/.hidden')
        )
        assert.are.equal(1, vim.fn.isdirectory(destination .. '/empty'))
        local nested = core.path.join(destination, core.path.name(source))
        assert.are.equal(0, vim.fn.isdirectory(nested))
        assert.are.same(
          { 'NEW' },
          vim.fn.readfile(source .. '/shared.txt')
        )
      end

      local function prepare_destination()
        vim.fn.mkdir(destination, 'p')
        write(destination .. '/shared.txt', 'OLD DESTINATION')
        write(destination .. '/keep.txt', 'KEEP')
      end

      it('copies contents to a new destination', function()
        assert.is_true(fs.copy_directory(source, destination))
        assert_contents()
      end)

      it('merges into an existing destination', function()
        prepare_destination()
        assert.is_true(fs.copy_directory(source, destination))
        assert_contents()
        assert.are.same(
          { 'KEEP' },
          vim.fn.readfile(destination .. '/keep.txt')
        )
      end)

      it('merges a source with a trailing separator', function()
        prepare_destination()
        assert.is_true(fs.copy_directory(source .. '/', destination))
        assert_contents()
      end)

      it('merges paths with spaces and special characters', function()
        local renamed = core.path.join(root, "source #%'")
        assert.are.equal(0, vim.fn.rename(source, renamed))
        source = renamed
        destination = core.path.join(root, "destination #%'")
        prepare_destination()
        assert.is_true(fs.copy_directory(source, destination))
        assert_contents()
      end)

      it('keeps contents when the source is missing', function()
        prepare_destination()
        assert.are.equal(0, vim.fn.delete(source, 'rf'))
        assert.is_false(fs.copy_directory(source, destination))
        assert.are.same(
          { 'OLD DESTINATION' },
          vim.fn.readfile(destination .. '/shared.txt')
        )
        assert.are.same(
          { 'KEEP' },
          vim.fn.readfile(destination .. '/keep.txt')
        )
      end)

      if not core.is_windows then
        it('copies a directory symlink as a symlink', function()
          local link = core.path.join(root, 'source-link')
          vim.fn.system({ 'ln', '-s', source, link })
          assert.are.equal(0, vim.v.shell_error)
          assert.is_true(fs.copy_directory(link, destination))
          assert.are.equal('link', vim.fn.getftype(destination))
          assert.are.equal(vim.fn.resolve(source), vim.fn.resolve(destination))
        end)

        it('preserves child symlinks when merging', function()
          local link = source .. '/child-link'
          vim.fn.system({ 'ln', '-s', source .. '/shared.txt', link })
          assert.are.equal(0, vim.v.shell_error)
          prepare_destination()
          assert.is_true(fs.copy_directory(source, destination))
          assert.are.equal(
            'link',
            vim.fn.getftype(destination .. '/child-link')
          )
          assert.are.same(
            { 'NEW' },
            vim.fn.readfile(destination .. '/child-link')
          )
        end)
      end
    end)
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

    -- Teardown
    if core.path.exists(srcdir) then
      result = fs.delete_directory(srcdir)
      assert.is_true(result)
      assert.is_false(core.path.is_directory(srcdir))
    end
    if core.path.exists(destdir) then
      result = fs.delete_directory(destdir)
      assert.is_true(result)
      assert.is_false(core.path.is_directory(destdir))
    end
  end)

  -- NOTE: Except Windows
  if not core.is_windows then
    describe('link file', function()
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
        local result = fs.create_file(path)
        assert.is_true(result)
        assert.is_true(core.path.filereadable(path))

        -- Create symbolic link file
        local linkpath = path .. '_ln'
        it('create link file:' .. path .. ' -> ' .. linkpath, function()
          core.system(('ln -s "%s" "%s"'):format(path, linkpath))
          assert.is_true(core.path.filereadable(linkpath))
        end)

        -- Delete symbolic link file
        it('delete link file:' .. linkpath, function()
          result = fs.delete_file(linkpath)
          assert.is_true(result)
          assert.is_false(core.path.filereadable(linkpath))
          assert.is_true(core.path.filereadable(path))
        end)

        -- Teardown
        result = fs.delete_file(path)
        assert.is_true(result)
        assert.is_false(core.path.filereadable(path))
      end
    end)

    describe('link directory', function()
      local dirpaths = {
        'testdir',
        '#testdir',
        'test#dir',
        '%testdir',
        'test%dir',
        '#test%dir',
        '%test#dir',
      }
      local filepaths = {
        'testfile',
        '#testfile',
        'test#file',
        '%testfile',
        'test%file',
        '#test%file',
        '%test#file',
      }
      for _, dirpath in ipairs(dirpaths) do
        local result = fs.create_directory(dirpath)
        assert.is_true(result)
        assert.is_true(core.path.is_directory(dirpath))

        -- Create files in directory
        for _, filepath in ipairs(filepaths) do
          local path = core.path.join(dirpath, filepath)
          result = fs.create_file(path)
          assert.is_true(result)
          assert.is_true(core.path.filereadable(path))
        end

        -- Create symbolic link file
        local linkpath = dirpath .. '_ln'
        it('create link file:' .. dirpath .. ' -> ' .. linkpath, function()
          core.system(('ln -s "%s" "%s"'):format(dirpath, linkpath))
          assert.is_true(core.path.is_directory(linkpath))
        end)

        -- Delete symbolic link file
        it('delete link file:' .. linkpath, function()
          result = fs.delete_file(linkpath)
          assert.is_true(result)
          assert.is_false(core.path.filereadable(linkpath))
          assert.is_true(core.path.is_directory(dirpath))
        end)

        -- Teardown
        result = fs.delete_directory(dirpath)
        assert.is_true(result)
        assert.is_false(core.path.is_directory(dirpath))
      end
    end)
  end
end)
