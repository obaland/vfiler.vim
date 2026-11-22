local core = require('vfiler/libs/core')
local git_backend = require('vfiler/libs/git')
local sort = require('vfiler/sort')
local u = require('tests/helper/utilities')
local View = require('vfiler/view')

describe('view', function()
  local root = vim.fn.fnamemodify('./', ':p')

  it('has_column', function()
    local vfiler = u.vfiler.start()
    local view = vfiler._view
    assert.is_true(view:has_column('name'))
    assert.is_false(view:has_column('xzy'))
    vfiler:quit(true)
  end)

  describe('drawing rows with different numbers of columns', function()
    local dir, filer, view

    before_each(function()
      dir = vim.fn.tempname()
      assert.equal(1, vim.fn.mkdir(dir))
      for _, name in ipairs({ 'a.txt', 'b.txt', 'c.txt', 'd.txt', 'e.txt' }) do
        assert.equal(0, vim.fn.writefile({}, core.path.join(dir, name)))
      end

      assert.is_true(require('vfiler').start(dir, {
        options = {
          auto_resize = false,
          columns = 'type,space',
          header = false,
          layout = 'right',
          new = true,
          sort = 'name',
          width = 40,
        },
      }))
      filer = require('vfiler/vfiler').get(vim.fn.bufnr())
      view = filer._view
      vim.fn.setwinvar(view:winid(), '&conceallevel', 0)
    end)

    after_each(function()
      if filer then
        filer:wipeout()
        filer = nil
      end
      vim.fn.delete(dir, 'rf')
    end)

    it('updates only the requested rows and keeps the cursor and marks', function()
      local suffix = '-'
      local column = view._columns.list[2]
      view._columns.list[2] = setmetatable({
        get_text = function()
          return suffix, #suffix
        end,
      }, { __index = column })
      view:redraw()

      local bufnr = view:bufnr()
      vim.api.nvim_win_set_cursor(view:winid(), { 2, 1 })
      vim.api.nvim_buf_set_mark(bufnr, 'a', 2, 1, {})
      local saved_view = vim.fn.winsaveview()

      suffix = '+'
      view:redraw({ 1, 2 })
      assert.are.same(
        { '[F] +', '[F] +', '[F] -' },
        vim.api.nvim_buf_get_lines(bufnr, 0, 3, true)
      )

      suffix = '*'
      view:redraw({ 1, 3 })
      assert.are.same(
        { '[F] *', '[F] +', '[F] *' },
        vim.api.nvim_buf_get_lines(bufnr, 0, 3, true)
      )
      assert.are.same({ 2, 1 }, vim.api.nvim_win_get_cursor(view:winid()))
      assert.are.same({ 2, 1 }, vim.api.nvim_buf_get_mark(bufnr, 'a'))
      assert.equal(saved_view.topline, vim.fn.winsaveview().topline)
    end)

    it('omits overflowing columns during full and partial redraws', function()
      local suffix = 'full'
      local column = view._columns.list[2]
      view._columns.list[2] = setmetatable({
        get_text = function(_, item)
          if item.name == 'b.txt' then
            return suffix, 1000
          end
          return suffix, #suffix
        end,
      }, { __index = column })

      view:redraw()
      assert.are.same(
        { '[F] full', '[F]', '[F] full' },
        vim.api.nvim_buf_get_lines(view:bufnr(), 0, 3, true)
      )

      suffix = 'partial'
      view:redraw({ 1, 2 })
      assert.are.same(
        { '[F] partial', '[F]', '[F] full' },
        vim.api.nvim_buf_get_lines(view:bufnr(), 0, 3, true)
      )
    end)
  end)

  describe('draw Git status', function()
    local vfiler, context, view, path
    local root_async = git_backend.root_async
    local status_async = git_backend.status_async

    before_each(function()
      vfiler, context, view = u.vfiler.start({
        options = { columns = 'name', layout = 'right', new = true },
      })
      path = core.path.join(context.root.path, 'README.md')
    end)

    after_each(function()
      git_backend.root_async = root_async
      git_backend.status_async = status_async
      vfiler:wipeout()
    end)

    local function cache_git_status()
      local root_path = core.path.normalize(vim.fn.resolve(context.root.path))
      local file_path = core.path.normalize(vim.fn.resolve(path))
      view._git._statuses[root_path] = {
        [file_path] = { us = ' ', them = 'M' },
      }
      return root_path
    end

    local function read_line()
      local lines = vim.api.nvim_buf_get_lines(view:bufnr(), 0, -1, false)
      for _, line in ipairs(lines) do
        if line:find('README.md', 1, true) then
          return line
        end
      end
      error('README.md is missing from the view')
    end

    local function draw_line(columns)
      context.options.columns = columns
      view:reset(context.options)
      vfiler:draw()
      return read_line()
    end

    it('keeps the file line unchanged without a Git column', function()
      local line = draw_line('name')
      cache_git_status()
      assert.equal(line, draw_line('name'))
    end)

    it('shows no Git marker before status is available', function()
      local line = draw_line('git,name')
      assert.is_nil(line:find('[ M]', 1, true))
    end)

    it('shows the Git marker when status is available', function()
      cache_git_status()
      local line = draw_line('git,name')
      assert.is_not_nil(line:find('[ M]', 1, true))
    end)

    it('clears the marker after a clean Git status result', function()
      local root_path = cache_git_status()
      assert.is_not_nil(draw_line('git,name'):find('[ M]', 1, true))
      view._git._git_executable = true
      git_backend.root_async = function(_, callback)
        callback(root_path)
      end
      git_backend.status_async = function(_, _, callback)
        callback({})
      end

      view:git_status_async(root_path, function(current)
        current:redraw()
      end)

      assert.is_nil(read_line():find('[ M]', 1, true))
      assert.is_nil(view:itemof(path).gitstatus)
    end)

    it('shows changes even when another repository is clean', function()
      local clean = core.path.normalize(vim.fn.tempname()) .. '/'
      view._git._statuses[clean] = {}
      cache_git_status()

      assert.is_not_nil(draw_line('git,name'):find('[ M]', 1, true))
    end)
  end)

  describe('conceal level on redraw', function()
    local vfiler, view, lnum

    local function set_conceallevel(level)
      vim.fn.setwinvar(view:winid(), '&conceallevel', level)
    end

    local function read_line()
      return vim.api.nvim_buf_get_lines(view:bufnr(), lnum - 1, lnum, true)[1]
    end

    before_each(function()
      vfiler = u.vfiler.start({
        options = { columns = 'name', layout = 'right', new = true },
      })
      view = vfiler._view
      lnum = view:indexof(core.path.join(root, 'README.md'))
      assert.not_equal(0, lnum)
    end)

    after_each(function()
      if vfiler then
        vfiler:wipeout()
      end
    end)

    it('applies the current conceal level when redrawing the list', function()
      local marked = read_line()
      assert.is_not_nil(marked:find('n..</README.md/>n', 1, true))

      set_conceallevel(0)
      view:redraw()
      assert.are.equal('README.md', vim.trim(read_line()))

      set_conceallevel(2)
      view:redraw()
      assert.are.equal(marked, read_line())
    end)

    it('applies the current conceal level when redrawing one line', function()
      local marked = read_line()
      set_conceallevel(0)
      view:redraw_line(lnum)
      assert.are.equal('README.md', vim.trim(read_line()))

      set_conceallevel(2)
      view:redraw_line(lnum)
      assert.are.equal(marked, read_line())
    end)
  end)

  describe('items on draw', function()
    local options, directory, view

    local function file(name, parent)
      parent = parent or directory
      return {
        name = name,
        path = parent.path .. name,
        type = 'file',
        level = parent.level + 1,
      }
    end

    local function draw_names()
      view:draw({ options = options, root = directory })
      local names = {}
      for item in view:walk_items() do
        table.insert(names, item.name)
      end
      return names
    end

    before_each(function()
      options = vim.deepcopy(require('vfiler/config').configs.options)
      options.columns = 'name'
      options.header = false
      options.show_hidden_files = false
      directory = { path = root, type = 'directory', level = 0 }
      view = View.new(options)
    end)

    after_each(function()
      sort.compares.test_view = nil
      sort.compares.Test_view = nil
    end)

    it('keeps each iterator on the list it started walking', function()
      local first, second = file('a.txt'), file('b.txt')
      directory.children = { second, first }
      view:draw({ options = options, root = directory })

      local started = view:walk_items()
      local pending = view:walk_items()
      assert.equal(first, started())

      local replacement = file('c.txt')
      directory.children = { replacement }
      view:draw({ options = options, root = directory })

      assert.equal(second, started())
      assert.is_nil(started())
      assert.equal(replacement, pending())
      assert.is_nil(pending())
    end)

    it('keeps the order across another draw and reorders after a rename', function()
      local last = file('z.txt')
      directory.children = { last, file('b.txt'), file('c.txt') }
      assert.are.same({ 'b.txt', 'c.txt', 'z.txt' }, draw_names())
      assert.are.same({ 'b.txt', 'c.txt', 'z.txt' }, draw_names())

      last.name = 'a.txt'
      last.path = directory.path .. last.name
      assert.are.same({ 'a.txt', 'b.txt', 'c.txt' }, draw_names())

      options.sort = 'Name'
      assert.are.same({ 'c.txt', 'b.txt', 'a.txt' }, draw_names())
    end)

    it('preserves table.sort ordering for names that compare equal', function()
      directory.children = {
        file('A.txt'),
        file('a.txt'),
        file('b.txt'),
        file('B.txt'),
        file('C.txt'),
      }
      local sorted = vim.list_extend({}, directory.children)
      for _ = 1, 2 do
        table.sort(sorted, sort.get('name'))
        local expected = {}
        for _, item in ipairs(sorted) do
          table.insert(expected, item.name)
        end
        assert.are.same(expected, draw_names())
      end
    end)

    it('uses the current custom comparator on every draw', function()
      local descending = false
      sort.set('test_view', function(item1, item2)
        if descending then
          return item1.name > item2.name
        end
        return item1.name < item2.name
      end)
      options.sort = 'test_view'
      directory.children = { file('b.txt'), file('a.txt'), file('c.txt') }
      assert.are.same({ 'a.txt', 'b.txt', 'c.txt' }, draw_names())

      descending = true
      assert.are.same({ 'c.txt', 'b.txt', 'a.txt' }, draw_names())
    end)

    it('updates path indexes when the header and hidden files are shown', function()
      local hidden, first = file('.hidden'), file('a.txt')
      directory.children = { first, hidden }
      options.header = true
      view:reset(options)
      view:draw({ options = options, root = directory })

      assert.are.equal(1, view:indexof(directory.path))
      assert.are.equal(2, view:indexof(first.path))
      assert.are.equal(0, view:indexof(hidden.path))
      assert.is_nil(view:itemof(hidden.path))

      options.show_hidden_files = true
      view:draw({ options = options, root = directory })

      assert.are.equal(2, view:indexof(hidden.path))
      assert.are.equal(3, view:indexof(first.path))
      assert.are.equal(hidden, view:itemof(hidden.path))
      assert.are.equal(first, view:get_item(3))
    end)

    it('sets and clears Git status for the root, branches, and files', function()
      local branch = {
        name = 'branch',
        path = directory.path .. 'branch/',
        type = 'directory',
        level = 1,
        opened = true,
      }
      local child, tail = file('child.txt', branch), file('tail.txt')
      branch.children = { child }
      directory.children = { tail, branch }

      local statuses = {}
      local items = { directory, branch, child, tail }
      for _, item in ipairs(items) do
        statuses[item.path] = { us = ' ', them = 'M' }
      end
      view._git.has_status = function()
        return true
      end
      view._git.status = function(_, path)
        return statuses[path]
      end

      options.columns = 'git,name'
      view:reset(options)
      assert.are.same({ 'branch', 'child.txt', 'tail.txt' }, draw_names())
      for _, item in ipairs(items) do
        assert.equal(statuses[item.path], item.gitstatus)
      end

      options.columns = 'name'
      view:reset(options)
      assert.are.same({ 'branch', 'child.txt', 'tail.txt' }, draw_names())
      for _, item in ipairs(items) do
        assert.is_nil(item.gitstatus)
      end
    end)

    it('skips an expanded directory subtree when moving between siblings', function()
      local branch = {
        name = 'branch',
        path = directory.path .. 'branch/',
        type = 'directory',
        level = 1,
        opened = true,
      }
      local child, tail = file('child.txt', branch), file('tail.txt')
      branch.children = { child }
      directory.children = { tail, branch }
      view:draw({ options = options, root = directory })

      assert.are.equal(2, view:indexof(child.path))
      assert.are.equal(3, view:indexof_next_sibling(1))
      assert.are.equal(1, view:indexof_prev_sibling(3))
      assert.are.equal(1, view:indexof_first_sibling(3))
      assert.are.equal(3, view:indexof_last_sibling(1))
    end)
  end)

  it('indexof', function()
    local vfiler = u.vfiler.start()
    local view = vfiler._view
    local path = core.path.join(root, 'README.md')
    local index = view:indexof(path)
    assert.not_equal(0, index)

    -- Purposely set a path that does not exist.
    path = core.path.join(root, 'foo.xxx')
    index = view:indexof(path)
    assert.equal(0, index)
  end)

  it('itemof', function()
    local vfiler = u.vfiler.start()
    local view = vfiler._view
    local path = core.path.join(root, 'README.md')
    local item = view:itemof(path)
    assert.not_nil(item)
    assert.equal(path, item.path)

    -- Purposely set a path that does not exist.
    path = core.path.join(root, 'foo.xxx')
    item = view:itemof(path)
    assert.is_nil(item)
  end)

  it('lineof', function()
    local vfiler = u.vfiler.start()
    local view = vfiler._view
    local path = core.path.join(root, 'README.md')
    local lnum = view:lineof(path)
    assert.is_true(lnum ~= 0)

    -- Purposely set a path that does not exist.
    path = core.path.join(root, 'foo.xxx')
    lnum = view:lineof(path)
    assert.is_true(lnum == 0)
  end)

  it('top_lnum', function()
    local vfiler = u.vfiler.start({
      options = {
        header = true,
      },
    })
    local view = vfiler._view
    assert.equal(2, view:top_lnum())
    vfiler:quit(true)

    vfiler = u.vfiler.start({
      options = {
        header = false,
      },
    })
    view = vfiler._view
    assert.equal(1, view:top_lnum())
    vfiler:quit(true)
  end)
end)
