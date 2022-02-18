local core = require('vfiler/libs/core')
local fs = require('vfiler/libs/filesystem')

describe('filesystem', function()
  local paths = vim.fn.glob('./*', 1, 1)
  describe('stat', function()
    for _, path in ipairs(paths) do
      it(path, function()
        local stat = fs.stat(path)
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

  --[[ TODO:
  describe('copy_file', function()
    local src = core.path.normalize('README.md')
    local dest = core.path.normalize('doc/README.md')
    it(('copy file: %s -> %s'):format(src, dest), function()
      assert.is_false(core.path.filereadable(dest))
      fs.copy_file(src, dest)
      assert.is_true(core.path.filereadable(dest))
    end)
  end)

  describe('copy_directory', function()
    local src = 'tests'
    local dest = 'lua/tests'
    it(('copy directory: %s -> %s'):format(src, dest), function()
      assert.is_false(core.path.is_directory(dest))
      fs.copy_directory(src, dest)
      assert.is_true(core.path.is_directory(dest))
    end)
  end)

  describe('move', function()
    local src_file = 'doc/README.md'
    local dest_file = 'autoload/README.md'
    local src_dir = 'lua/tests'
    local dest_dir = 'autoload/tests'

    it(('move file: %s -> %s'):format(src_file, dest_file), function()
      assert.is_true(core.path.filereadable(src_file))
      assert.is_false(core.path.filereadable(dest_file))
      fs.move(src_file, dest_file)
      assert.is_true(core.path.filereadable(dest_file))
      assert.is_false(core.path.filereadable(src_file))
    end)

    it(('move directory: %s -> %s'):format(src_dir, dest_dir), function()
      assert.is_true(core.path.is_directory(src_dir))
      assert.is_false(core.path.is_directory(dest_dir))
      fs.move(src_dir, dest_dir)
      assert.is_true(core.path.is_directory(dest_dir))
      assert.is_false(core.path.is_directory(src_dir))
    end)
  end)
  ]]
end)
