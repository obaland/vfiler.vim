local core = require('vfiler/libs/core')
local backend = require('vfiler/libs/git')

local Git = require('vfiler/git')

describe('Git', function()
  it('status_async', function()
    local git = Git.new({})
    git:status_async(core.path.normalize('./'), function(self, root, status)
      assert.is_not_nil(self)
      assert.is_not_nil(root)
      assert.is_not_nil(status)
    end)
  end)

  it('reset', function()
    local git = Git.new({})
    git:reset({})
  end)

  it('status', function()
    local git = Git.new({})
    git:status(core.path.normalize('./'))
  end)

  it('walk_status', function()
    local git = Git.new({})
    for path, status in git:walk_status() do
      assert.is_not_nil(path)
      assert.is_not_nil(status)
    end
  end)

  describe('status path resolution', function()
    local git, root, nested
    local modified = { us = ' ', them = 'M' }
    local staged = { us = 'A', them = ' ' }

    before_each(function()
      local dir = vim.fn.tempname()
      assert.equal(1, vim.fn.mkdir(dir .. '/nested', 'p'))
      root = core.path.normalize(dir)
      nested = root .. 'nested/'
      assert.equal(0, vim.fn.writefile({}, nested .. 'tracked.txt'))
      git = Git.new({ enabled = true })
      git._statuses[nested] = {
        [nested .. 'tracked.txt'] = modified,
        [nested .. 'removed.txt'] = { us = ' ', them = 'D' },
        [nested] = staged,
      }
    end)

    after_each(function()
      vim.fn.delete(root, 'rf')
    end)

    it('finds tracked, deleted, and directory entries in a nested repository', function()
      assert.are.same(modified, git:status(nested .. 'tracked.txt'))
      assert.are.same({ us = ' ', them = 'D' }, git:status(nested .. 'removed.txt'))
      assert.are.same(staged, git:status(nested:sub(1, -2)))
    end)

    if not core.is_windows then
      it('looks up target paths through file and directory symlinks', function()
        local alias = root .. 'alias.txt'
        local alias_dir = root .. 'alias-dir'
        assert(vim.loop.fs_symlink(nested .. 'tracked.txt', alias))
        assert(vim.loop.fs_symlink(nested, alias_dir))
        assert.are.same(modified, git:status(alias))
        assert.are.same(modified, git:status(alias_dir .. '/tracked.txt'))
      end)

      it('reads the new target after replacing a regular file with a symlink', function()
        local path = nested .. 'before.txt'
        assert.equal(0, vim.fn.writefile({}, path))
        git._statuses[nested][path] = staged
        assert.are.same(staged, git:status(path))

        assert.equal(0, vim.fn.delete(path))
        assert(vim.loop.fs_symlink(nested .. 'tracked.txt', path))
        assert.are.same(modified, git:status(path))
      end)
    end
  end)

  describe('overlapping status requests', function()
    local root_async = backend.root_async
    local status_async = backend.status_async
    local git, jobs, root

    local function finish(job, status)
      if not job.stopped then
        job.callback(status)
      end
    end

    local function file_status(path, state)
      return { [path] = { us = ' ', them = state } }
    end

    before_each(function()
      root = core.path.normalize(vim.fn.tempname())
      git = Git.new({ enabled = true })
      git._git_executable = true
      jobs = {}
      backend.root_async = function(path, callback)
        callback(path)
      end
      backend.status_async = function(path, _, callback)
        local job = { root = path, callback = callback }
        function job:stop()
          self.stopped = true
        end
        table.insert(jobs, job)
        return job
      end
    end)

    after_each(function()
      backend.root_async = root_async
      backend.status_async = status_async
    end)

    it('reports the latest status when requests overlap', function()
      local path = core.path.join(root, 'file.txt')
      local old = file_status(path, 'M')
      local latest = file_status(path, 'D')
      local results = {}
      local function receive(_, _, status)
        table.insert(results, status)
      end

      for _ = 1, 4 do
        git:status_async(root, receive)
      end
      local index = 1
      while jobs[index] do
        finish(jobs[index], index == 1 and old or latest)
        index = index + 1
      end

      assert.are.same({ latest }, results)
      assert.are.same(latest[path], git:status(path))
    end)

    it('reports the latest request made while finding the root', function()
      local lookups, requests = {}, {}
      backend.root_async = function(_, callback)
        table.insert(lookups, callback)
        return {}
      end
      for i = 1, 4 do
        git:status_async(root, function()
          table.insert(requests, i)
        end)
      end
      for _, resolve in ipairs(lookups) do
        resolve(root)
      end
      local index = 1
      while jobs[index] do
        finish(jobs[index], {})
        index = index + 1
      end

      assert.are.same({ 4 }, requests)
    end)

    it('uses the current root after an earlier lookup completes', function()
      local dir = core.path.join(root, 'sub')
      local resolved, roots = root, {}
      backend.root_async = function(_, callback)
        callback(resolved)
      end
      local function receive(_, result)
        table.insert(roots, result)
      end

      git:status_async(dir, receive)
      finish(jobs[1], {})
      resolved = dir
      git:status_async(dir, receive)
      finish(jobs[2], {})

      assert.are.same({ root, dir }, roots)
    end)

    it('can retry after the root lookup fails to start', function()
      local start_root = backend.root_async
      backend.root_async = function() end
      git:status_async(root, function() end)
      backend.root_async = start_root

      local result
      git:status_async(root, function(_, path)
        result = path
      end)
      finish(jobs[1], {})

      assert.are.equal(root, result)
    end)

    it('updates repositories independently', function()
      local other = root .. '-other'
      local roots = {}
      local function receive(_, path)
        table.insert(roots, path)
      end

      git:status_async(root, receive)
      git:status_async(other, receive)
      finish(jobs[2], {})
      finish(jobs[1], {})

      assert.are.same({ other, root }, roots)
    end)

    it('accepts another request after a result is delivered', function()
      local path = core.path.join(root, 'file.txt')
      local changed = file_status(path, 'M')
      local function receive() end

      git:status_async(root, receive)
      finish(jobs[1], changed)
      assert.are.same(changed[path], git:status(path))

      git:status_async(root, receive)
      finish(jobs[2], {})
      assert.is_nil(git:status(path))
    end)

    it('can retry after the status job fails to start', function()
      local start_status = backend.status_async
      backend.status_async = function() end
      git:status_async(root, function() end)
      backend.status_async = start_status

      local result
      git:status_async(root, function(_, _, status)
        result = status
      end)
      finish(jobs[1], {})

      assert.are.same({}, result)
    end)
  end)
end)
