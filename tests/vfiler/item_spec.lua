local core = require('vfiler/libs/core')
local fs = require('vfiler/libs/filesystem')

local Directory = require('vfiler/items/directory')
local File = require('vfiler/items/file')

describe('item', function()
  local root = vim.fn.fnamemodify('./', ':p')

  describe('directory', function()
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
    it('create and delete', function()
      local filepath = core.path.join(root, 'foo')
      local file = File.create(filepath)
      assert.is_not_nil(file)
      assert.is_true(core.path.exists(filepath))

      local result = file:delete()
      assert.is_true(result)
      assert.is_false(core.path.exists(filepath))
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
