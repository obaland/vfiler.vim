local git = require('vfiler/libs/git')

describe('git', function()
  local rootpath = vim.fn.fnamemodify('./', ':p')

  describe('get_toplevel', function()
    it('call', function()
      -- TODO:
      --local path = git.get_toplevel(rootpath)
      --assert.is_not_nil(path)
    end)
  end)

  describe('reload_status_async', function()
    it('call', function()
      local options = {}
      local job = git.reload_status_async(rootpath, options, function(status)
        assert.is_not_nil(status)
      end)
      assert.is_not_nil(job)
      job:wait()

      options = {
        untracked = ture,
      }
      job = git.reload_status_async(rootpath, options, function(status)
        assert.is_not_nil(status)
      end)
      assert.is_not_nil(job)
      job:wait()

      options = {
        ignored = ture,
      }
      job = git.reload_status_async(rootpath, options, function(status)
        assert.is_not_nil(status)
      end)
      assert.is_not_nil(job)
      job:wait()

      options = {
        untracked = ture,
        ignored = ture,
      }
      job = git.reload_status_async(rootpath, options, function(status)
        assert.is_not_nil(status)
      end)
      assert.is_not_nil(job)
      job:wait()
    end)
  end)

  describe('reload_status_file', function()
    it('call', function()
      local options = {}
      local path = vim.fn.fnamemodify('./README.md', ':p')
      local status = git.reload_status_file(rootpath, path, options)

      options = {
        untracked = ture,
      }
      status = git.reload_status_file(rootpath, path, options)

      options = {
        ignored = ture,
      }
      status = git.reload_status_file(rootpath, path, options)

      options = {
        untracked = ture,
        ignored = ture,
      }
      status = git.reload_status_file(rootpath, path, options)
    end)
  end)
end)
