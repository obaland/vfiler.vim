local core = require('vfiler/libs/core')
local preview_actions = require('vfiler/actions/preview')
local VFiler = require('vfiler/vfiler')

describe('preview actions', function()
  local filer, context, view, root

  local function move_to(name)
    view:move_cursor(core.path.join(root, name))
    vim.cmd('doautocmd <nomodeline> CursorMoved')
  end

  local function shows(text)
    local preview = context.in_preview.preview
    if not (preview and preview.opened) then
      return false
    end
    local bufnr = vim.api.nvim_win_get_buf(preview._window:id())
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)
    return lines[1] == text
  end

  before_each(function()
    filer, context = nil, nil
    root = vim.fn.tempname()
    assert.are.equal(1, vim.fn.mkdir(core.path.join(root, 'directory'), 'p'))
    for _, name in ipairs({ 'first', 'second', 'third' }) do
      local path = core.path.join(root, name .. '.txt')
      assert.are.equal(0, vim.fn.writefile({ name }, path))
    end

    assert.is_true(require('vfiler').start(root, {
      options = {
        columns = 'name',
        new = true,
        preview = { layout = 'floating' },
      },
    }))
    filer = VFiler.get(vim.fn.bufnr())
    context, view = filer._context, filer._view
  end)

  after_each(function()
    if context and context.in_preview.preview then
      context.in_preview.preview:close()
    end
    if filer then
      filer:wipeout()
    end
    vim.fn.delete(root, 'rf')
  end)

  it('shows the last file after successive cursor moves', function()
    move_to('first.txt')
    filer:do_action(preview_actions.toggle_auto_preview)
    assert.is_true(shows('first'))

    move_to('second.txt')
    move_to('third.txt')

    assert.is_true(vim.wait(500, function()
      return shows('third')
    end))
  end)

  it('updates the automatic preview immediately with a zero delay', function()
    context.options.preview.delay = 0
    move_to('first.txt')
    filer:do_action(preview_actions.toggle_auto_preview)
    assert.is_true(shows('first'))

    move_to('second.txt')

    assert.is_true(shows('second'))
  end)

  it('does not reopen the preview after moving onto a directory', function()
    move_to('first.txt')
    filer:do_action(preview_actions.toggle_auto_preview)
    move_to('second.txt')
    move_to('directory/')

    local preview = context.in_preview.preview
    assert.is_false(preview.opened)
    assert.is_false(vim.wait(150, function()
      return preview.opened
    end))
  end)

  it('does not reopen the preview after switching it off', function()
    move_to('directory/')
    filer:do_action(preview_actions.toggle_auto_preview)
    local preview = context.in_preview.preview
    move_to('first.txt')
    filer:do_action(preview_actions.toggle_auto_preview)

    assert.is_nil(context.in_preview.preview)
    assert.is_false(vim.wait(150, function()
      return preview.opened
    end))
  end)

  it('does not reopen the preview after leaving the filer', function()
    move_to('directory/')
    filer:do_action(preview_actions.toggle_auto_preview)
    local preview = context.in_preview.preview
    move_to('first.txt')
    vim.cmd('enew')

    assert.is_false(vim.wait(150, function()
      return preview.opened
    end))
  end)

  it('opens a manual preview immediately and closes it on movement', function()
    move_to('first.txt')
    filer:do_action(preview_actions.toggle_preview)
    assert.is_true(shows('first'))

    move_to('second.txt')

    assert.is_nil(context.in_preview.preview)
  end)
end)
