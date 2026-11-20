local actions = require('vfiler/actions/file_operation')
local cmdline = require('vfiler/libs/cmdline')
local core = require('vfiler/libs/core')
local VFiler = require('vfiler/vfiler')

describe('file operation: rename one file', function()
  local root, source, destination, filer
  local original_input, original_confirm
  local confirmed_names, rename_calls

  local function rename_to(name, response)
    cmdline.input = function()
      return name
    end
    cmdline.util.confirm_overwrite = function(target)
      table.insert(confirmed_names, target)
      return response
    end
    filer:do_action(actions.rename)
  end

  local function assert_unchanged()
    assert.are.same({ 'SOURCE' }, vim.fn.readfile(source))
    assert.are.same({ 'DESTINATION' }, vim.fn.readfile(destination))
    assert.are.equal(0, rename_calls)
  end

  before_each(function()
    filer = nil
    original_input = cmdline.input
    original_confirm = cmdline.util.confirm_overwrite
    confirmed_names, rename_calls = {}, 0

    root = vim.fn.tempname()
    vim.fn.mkdir(root, 'p')
    source = core.path.join(root, 'source.txt')
    destination = core.path.join(root, 'destination.txt')
    vim.fn.writefile({ 'SOURCE' }, source)
    vim.fn.writefile({ 'DESTINATION' }, destination)

    assert.is_true(require('vfiler').start(root, {
      options = {
        new = true,
        header = false,
        columns = 'name',
        session = 'none',
        git = { enabled = false },
      },
    }))
    filer = VFiler.get(vim.fn.bufnr())
    filer:move_cursor(source)

    local item = filer._view:get_item()
    assert.are.equal(source, item.path)

    local original_rename = item.rename
    item.rename = function(self, name)
      rename_calls = rename_calls + 1
      return original_rename(self, name)
    end
  end)

  after_each(function()
    cmdline.input = original_input
    cmdline.util.confirm_overwrite = original_confirm
    if filer then
      filer:wipeout()
    end
    if root then
      vim.fn.delete(root, 'rf')
    end
  end)

  it('renames without confirmation when the target does not exist', function()
    local newpath = core.path.join(root, 'new.txt')

    rename_to('new.txt')

    assert.are.same({}, confirmed_names)
    assert.are.equal(1, rename_calls)
    assert.are.equal(0, vim.fn.filereadable(source))
    assert.are.same({ 'SOURCE' }, vim.fn.readfile(newpath))
    assert.are.same({ 'DESTINATION' }, vim.fn.readfile(destination))
  end)

  it('keeps both files when overwrite is declined', function()
    rename_to('destination.txt', cmdline.choice.NO)

    assert.are.same({ 'destination.txt' }, confirmed_names)
    assert_unchanged()
  end)

  it('keeps both files when the confirmation is cancelled', function()
    rename_to('destination.txt', nil)

    assert.are.same({ 'destination.txt' }, confirmed_names)
    assert_unchanged()
  end)

  it('overwrites only after confirmation', function()
    rename_to('destination.txt', cmdline.choice.YES)

    assert.are.same({ 'destination.txt' }, confirmed_names)
    assert.are.equal(1, rename_calls)
    assert.are.equal(0, vim.fn.filereadable(source))
    assert.are.same({ 'SOURCE' }, vim.fn.readfile(destination))
  end)

  it('does nothing when the name is unchanged', function()
    rename_to('source.txt', cmdline.choice.NO)

    assert.are.same({}, confirmed_names)
    assert_unchanged()
  end)

  it('does nothing when the input is empty', function()
    rename_to('')

    assert.are.same({}, confirmed_names)
    assert_unchanged()
  end)
end)
