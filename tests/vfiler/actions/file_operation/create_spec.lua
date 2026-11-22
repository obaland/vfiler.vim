local actions = require('vfiler/actions/file_operation')
local cmdline = require('vfiler/libs/cmdline')
local core = require('vfiler/libs/core')
local VFiler = require('vfiler/vfiler')

describe('file operation: create', function()
  local input = cmdline.input
  local confirm_overwrite = cmdline.util.confirm_overwrite
  local root, target, filers

  local function start(path)
    assert.is_true(require('vfiler').start(path, {
      options = {
        columns = 'name',
        header = false,
        layout = 'right',
        new = true,
        width = 24,
      },
    }))
    local filer = VFiler.get(vim.fn.bufnr())
    table.insert(filers, filer)
    return filer, filer._view
  end

  local function create(filer, action, name)
    cmdline.input = function()
      return name
    end
    filer:do_action(action)
  end

  before_each(function()
    filers = {}
    root = vim.fn.tempname()
    target = core.path.join(root, 'target')
    assert.are.equal(1, vim.fn.mkdir(target, 'p'))
    local time = 1000000000
    assert(vim.loop.fs_utime(target, time, time))
  end)

  after_each(function()
    cmdline.input = input
    cmdline.util.confirm_overwrite = confirm_overwrite
    for i = #filers, 1, -1 do
      filers[i]:wipeout()
    end
    vim.fn.delete(root, 'rf')
  end)

  for _, case in ipairs({
    { action = actions.new_file, kind = 'file' },
    { action = actions.new_directory, kind = 'dir' },
  }) do
    it('creates each distinct ' .. case.kind .. ' and selects the first', function()
      local filer, view = start(target)
      local confirmations = 0
      cmdline.util.confirm_overwrite = function()
        confirmations = confirmations + 1
        return cmdline.choice.NO
      end

      create(filer, case.action, 'z name, a, z name, middle, a')

      for _, name in ipairs({ 'z name', 'a', 'middle' }) do
        local path = core.path.join(target, name)
        assert.are.equal(case.kind, vim.fn.getftype(path))
      end
      assert.are.equal('z name', view:get_item().name)
      assert.are.equal(0, confirmations)
    end)
  end

  it('shows a new file in both filers rooted at the same directory', function()
    local _, other_view = start(target)
    local filer, view = start(target)
    local path = core.path.join(target, 'created.txt')

    create(filer, actions.new_file, 'created.txt')

    assert.are.equal(1, vim.fn.filereadable(path))
    assert.are.equal(path, view:get_item().path)
    assert.is_not_nil(other_view:itemof(path))
  end)

  it('shows a new directory in an expanded tree in another filer', function()
    local parent, parent_view = start(root)
    local directory = parent:get_root_item().child_directories.target
    directory:open()
    parent:draw()
    local filer = start(target)
    local path = core.path.join(target, 'created')

    create(filer, actions.new_directory, 'created')

    assert.are.equal(1, vim.fn.isdirectory(path))
    assert.is_true(parent_view:itemof(directory.path).opened)
    assert.is_not_nil(parent_view:itemof(path .. '/'))
  end)

  if not core.is_windows then
    it('shows a new file through an expanded directory symlink', function()
      local other = core.path.join(root, 'other')
      local link = core.path.join(other, 'link')
      assert.are.equal(1, vim.fn.mkdir(other))
      assert(vim.loop.fs_symlink(target, link))
      local linked, linked_view = start(other)
      linked:get_root_item().child_directories.link:open()
      linked:draw()
      local filer = start(target)

      create(filer, actions.new_file, 'created.txt')

      assert.is_not_nil(linked_view:itemof(link .. '/created.txt'))
    end)
  end
end)
