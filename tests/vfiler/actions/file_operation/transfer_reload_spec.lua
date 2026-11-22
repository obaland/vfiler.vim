local actions = require('vfiler/actions/file_operation')
local clipboard = require('vfiler/clipboard')
local cmdline = require('vfiler/libs/cmdline')
local core = require('vfiler/libs/core')
local VFiler = require('vfiler/vfiler')

describe('file operation: refresh after a transfer', function()
  local input, confirm = cmdline.input, cmdline.util.confirm_overwrite_or_rename
  local root, source, destination, alternate, filers

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
    clipboard.clear()
    root = vim.fn.tempname()
    source = core.path.join(root, 'source')
    destination = core.path.join(root, 'destination')
    alternate = core.path.join(root, 'alternate')
    for _, directory in ipairs({ source, destination, alternate }) do
      assert.are.equal(1, vim.fn.mkdir(directory, 'p'))
    end
    assert.are.equal(0, vim.fn.writefile({ 'source' }, source .. '/file.txt'))
    local time = 1000000000
    assert(vim.loop.fs_utime(source, time, time))
    assert(vim.loop.fs_utime(destination, time, time))
    assert(vim.loop.fs_utime(alternate, time, time))
  end)

  after_each(function()
    cmdline.input, cmdline.util.confirm_overwrite_or_rename = input, confirm
    clipboard.clear()
    for i = #filers, 1, -1 do
      filers[i]:wipeout()
    end
    vim.fn.delete(root, 'rf')
  end)

  it('shows a copy in the linked filer and clears the source selection', function()
    local linked, target_view = start(destination)
    local filer, source_view = start(source)
    filer:link(linked)
    source_view:itemof(source .. '/file.txt').selected = true
    filer:draw()

    filer:do_action(actions.copy_to_filer)

    assert.is_not_nil(target_view:itemof(destination .. '/file.txt'))
    assert.is_false(source_view:itemof(source .. '/file.txt').selected)
  end)

  it('updates both filers after moving a file to a linked filer', function()
    local linked, target_view = start(destination)
    local filer, source_view = start(source)
    filer:link(linked)

    filer:do_action(actions.move_to_filer)

    assert.is_nil(source_view:itemof(source .. '/file.txt'))
    assert.is_not_nil(target_view:itemof(destination .. '/file.txt'))
  end)

  it('refreshes another view of the move source after a clipboard paste', function()
    local _, source_view = start(source)
    local from = start(source)
    from:do_action(actions.move)
    local dest, target_view = start(destination)

    dest:do_action(actions.paste)

    assert.is_nil(source_view:itemof(source .. '/file.txt'))
    assert.is_not_nil(target_view:itemof(destination .. '/file.txt'))
    assert.is_nil(clipboard.get_current())
  end)

  it('refreshes the actual destination when a conflicting file is renamed', function()
    local _, target_view = start(alternate)
    local from = start(source)
    from:do_action(actions.copy)
    local original = destination .. '/file.txt'
    assert.are.equal(0, vim.fn.writefile({ 'original' }, original))
    local dest = start(destination)
    cmdline.util.confirm_overwrite_or_rename = function()
      return cmdline.choice.RENAME
    end
    cmdline.input = function()
      return '../alternate/renamed.txt'
    end

    dest:do_action(actions.paste)

    assert.are.same({ 'original' }, vim.fn.readfile(original))
    assert.is_not_nil(target_view:itemof(alternate .. '/renamed.txt'))
  end)

  it('shows destination changes left behind by a failed copy', function()
    local linked, target_view = start(destination)
    local filer, source_view = start(source)
    filer:link(linked)
    local item = source_view:itemof(source .. '/file.txt')
    item.copy = function(_, path)
      assert.are.equal(0, vim.fn.writefile({ 'partial' }, path))
      return nil
    end

    filer:do_action(actions.copy_to_filer)

    assert.is_not_nil(target_view:itemof(destination .. '/file.txt'))
  end)
end)
