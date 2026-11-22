local actions = require('vfiler/actions/file_operation')
local cmdline = require('vfiler/libs/cmdline')
local core = require('vfiler/libs/core')
local VFiler = require('vfiler/vfiler')

describe('file operation: refresh after rename and delete', function()
  local input, confirm = cmdline.input, cmdline.confirm
  local root, source, destination, filers

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

  before_each(function()
    filers = {}
    root = vim.fn.tempname()
    source = core.path.join(root, 'source')
    destination = core.path.join(root, 'destination')
    assert.are.equal(1, vim.fn.mkdir(source, 'p'))
    assert.are.equal(1, vim.fn.mkdir(destination))
    assert.are.equal(0, vim.fn.writefile({}, source .. '/a.txt'))
    assert.are.equal(0, vim.fn.writefile({}, source .. '/b.txt'))
    local time = 1000000000
    assert(vim.loop.fs_utime(source, time, time))
    assert(vim.loop.fs_utime(destination, time, time))
  end)

  after_each(function()
    cmdline.input, cmdline.confirm = input, confirm
    for i = #filers, 1, -1 do
      filers[i]:wipeout()
    end
    vim.fn.delete(root, 'rf')
  end)

  it('updates both directories when a file is renamed to another path', function()
    local _, target_view = start(destination)
    local filer, source_view = start(source)
    local path = source .. '/a.txt'
    filer:move_cursor(path)
    cmdline.input = function()
      return '../destination/renamed.txt'
    end

    filer:do_action(actions.rename)

    assert.is_nil(source_view:itemof(path))
    assert.is_not_nil(target_view:itemof(destination .. '/renamed.txt'))
  end)

  it('shows the results of a bulk rename in another filer', function()
    local _, other_view = start(source)
    local filer, view = start(source)
    view:itemof(source .. '/a.txt').selected = true
    view:itemof(source .. '/b.txt').selected = true
    filer:do_action(actions.rename)
    local extension = filer._context.extension
    assert.is_not_nil(extension)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'new-a.txt', 'new-b.txt' })

    extension:execute()

    assert.is_nil(other_view:itemof(source .. '/a.txt'))
    assert.is_nil(other_view:itemof(source .. '/b.txt'))
    assert.is_not_nil(other_view:itemof(source .. '/new-a.txt'))
    assert.is_not_nil(other_view:itemof(source .. '/new-b.txt'))
  end)

  if not core.is_windows then
    it('removes a deleted file from an expanded directory symlink', function()
      local link = destination .. '/link'
      assert(vim.loop.fs_symlink(source, link))
      local linked, linked_view = start(destination)
      linked:get_root_item().child_directories.link:open()
      linked:draw()
      local filer = start(source)
      filer:move_cursor(source .. '/a.txt')
      assert.is_not_nil(linked_view:itemof(link .. '/a.txt'))
      cmdline.confirm = function()
        return cmdline.choice.YES
      end

      filer:do_action(actions.delete)

      assert.is_nil(linked_view:itemof(link .. '/a.txt'))
      assert.is_not_nil(linked_view:itemof(link .. '/b.txt'))
    end)
  end
end)
