local git = require('vfiler/libs/git')

describe('git', function()
  local rootpath = vim.fn.fnamemodify('./', ':p')

  describe('root', function()
    it('root:' .. rootpath, function()
      local path = git.root(rootpath)
      assert.is_not_nil(path)
    end)
  end)

  describe('get_toplevel_async', function()
    it('root:' .. rootpath, function()
      local job = git.root_async(rootpath, function(path)
        assert.is_not_nil(path)
      end)
      assert.is_not_nil(job)
      job:wait()
    end)
  end)

  describe('status_file', function()
    local path = vim.fn.fnamemodify('./README.md', ':p')

    it('default', function()
      local options = {}
      git.status_file(rootpath, path, options)
    end)
    it('untracked option', function()
      local options = {
        untracked = true,
      }
      git.status_file(rootpath, path, options)
    end)
    it('ignored option', function()
      local options = {
        ignored = true,
      }
      git.status_file(rootpath, path, options)
    end)
    it('untracked and ignored options', function()
      local options = {
        untracked = true,
        ignored = true,
      }
      git.status_file(rootpath, path, options)
    end)
  end)

  describe('status_async', function()
    it('default', function()
      local options = {}
      local job = git.status_async(rootpath, options, function(status)
        assert.is_not_nil(status)
      end)
      assert.is_not_nil(job)
      job:wait()
    end)

    it('untracked option', function()
      local options = {
        untracked = true,
      }
      local job = git.status_async(rootpath, options, function(status)
        assert.is_not_nil(status)
      end)
      assert.is_not_nil(job)
      job:wait()
    end)

    it('ignored option', function()
      local options = {
        ignored = true,
      }
      local job = git.status_async(rootpath, options, function(status)
        assert.is_not_nil(status)
      end)
      assert.is_not_nil(job)
      job:wait()
    end)

    it('untracked and ignored options', function()
      local options = {
        untracked = true,
        ignored = true,
      }
      local job = git.status_async(rootpath, options, function(status)
        assert.is_not_nil(status)
      end)
      assert.is_not_nil(job)
      job:wait()
    end)
  end)
end)
