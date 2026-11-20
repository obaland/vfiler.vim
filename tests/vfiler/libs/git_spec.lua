local core = require('vfiler/libs/core')
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

  describe('status filenames', function()
    local temp, root

    local function run(args)
      local command = { 'git', '-C', root }
      for _, arg in ipairs(args) do
        table.insert(command, arg)
      end
      local result = vim.fn.system(command)
      assert.are.equal(0, vim.v.shell_error, result)
      return result
    end

    local function path(name)
      return root .. name
    end

    local function write(name, contents)
      local filepath = path(name)
      vim.fn.mkdir(vim.fn.fnamemodify(filepath, ':h'), 'p')
      assert.are.equal(
        0,
        vim.fn.writefile({ contents or 'CONTENT' }, filepath)
      )
    end

    local function commit()
      run({ 'add', '--all' })
      run({
        '-c',
        'user.name=VFiler Tests',
        '-c',
        'user.email=vfiler-tests@example.invalid',
        '-c',
        'commit.gpgsign=false',
        'commit',
        '--quiet',
        '-m',
        'fixture',
      })
    end

    local function statuses(options)
      local result
      local job = git.status_async(root, options or {
        untracked = true,
        ignored = false,
      }, function(value)
        result = value
      end)
      job:wait(5000)
      assert.is_not_nil(result, 'git status did not complete')
      return result
    end

    local function assert_status(result, name, us, them)
      assert.are.same({ us = us, them = them }, result[path(name)])
    end

    before_each(function()
      temp = vim.fn.tempname()
      root = core.path.normalize(temp .. '/repository')
      vim.fn.mkdir(root, 'p')
      root = core.path.normalize(root)
      run({ 'init', '--quiet' })
      run({ 'config', 'core.quotepath', 'true' })
      run({ 'config', 'core.autocrlf', 'false' })
      local hooks = core.path.join(temp, 'empty-hooks')
      vim.fn.mkdir(hooks, 'p')
      run({ 'config', 'core.hooksPath', hooks })
    end)

    after_each(function()
      vim.fn.delete(temp, 'rf')
    end)

    local arrow = core.is_windows and ' → ' or ' -> '
    local arrow_name = 'a' .. arrow .. 'b.txt'
    local names = {
      'plain.txt',
      '日本語.txt',
      arrow_name,
      'space name.txt',
      '資料/日本語.txt',
    }
    if not core.is_windows then
      for _, name in ipairs({
        '"quoted".txt',
        'tab\tname.txt',
        'line\nname.txt',
        'back\\slash.txt',
        'literal\\346.txt',
        'trailing space.txt ',
      }) do
        table.insert(names, name)
      end
    end

    for _, name in ipairs(names) do
      it('reads an untracked name ' .. vim.inspect(name), function()
        write(name)
        assert_status(statuses(), name, '?', '?')
      end)
    end

    it('reads Japanese names with core.quotepath disabled', function()
      run({ 'config', 'core.quotepath', 'false' })
      write('日本語.txt')
      assert_status(statuses(), '日本語.txt', '?', '?')
    end)

    it('reads a modified Japanese file', function()
      write('日本語.txt')
      commit()
      write('日本語.txt', 'CHANGED')
      assert_status(statuses(), '日本語.txt', ' ', 'M')
    end)

    it('reads a deleted Japanese file', function()
      write('日本語.txt')
      commit()
      assert.are.equal(0, vim.fn.delete(path('日本語.txt')))
      assert_status(statuses(), '日本語.txt', ' ', 'D')
    end)

    it('reads a renamed file with Japanese names and arrows', function()
      local old = '旧' .. arrow .. '名前.txt'
      local new = '新' .. arrow .. '名前.txt'
      write(old)
      commit()
      run({ 'mv', '--', old, new })
      local result = statuses()
      assert_status(result, new, 'R', ' ')
      assert.is_nil(result[path(old)])
    end)

    it('reads an ordinary rename', function()
      write('old.txt')
      commit()
      run({ 'mv', '--', 'old.txt', 'new.txt' })
      assert_status(statuses(), 'new.txt', 'R', ' ')
    end)

    if not core.is_windows then
      it('reads renamed quoted names with embedded arrows', function()
        local old = 'from "quote\\x" -> old.txt'
        local new = 'to "quote\\y" -> new.txt'
        write(old)
        commit()
        run({ 'mv', '--', old, new })
        assert_status(statuses(), new, 'R', ' ')
      end)
    end

    it('reads ignored Japanese names', function()
      write('.gitignore', '無視.txt')
      write('無視.txt')
      assert_status(statuses({
        untracked = true,
        ignored = true,
      }), '無視.txt', '!', '!')
    end)

    it('aggregates changes under a Japanese directory', function()
      write('資料/日本語.txt')
      commit()
      write('資料/日本語.txt', 'CHANGED')
      local result = statuses()
      assert_status(result, '資料/日本語.txt', ' ', 'M')
      assert_status(result, '資料/', ' ', '*')
    end)

    for _, name in ipairs({ 'plain.txt', '日本語.txt', arrow_name }) do
      it('keeps synchronous status working for ' .. name, function()
        write(name)
        assert_status(git.status_file(root, path(name), {
          untracked = true,
          ignored = false,
        }), name, '?', '?')
      end)
    end
  end)
end)
