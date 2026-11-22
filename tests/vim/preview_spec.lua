local actions = require('vfiler/actions/preview')
local config = require('vfiler/actions/config')
local VFiler = require('vfiler/vfiler')
local compat = require('vfiler/libs/vim')

local original_hook = config.configs.hook.read_preview_file
local root = vim.fn.tempname()
local filer
assert(vim.fn.mkdir(root .. '/directory', 'p') == 1)

local ok, err = xpcall(function()
  assert(vim.fn.writefile(vim.list({ 'first' }), root .. '/first.txt') == 0)
  assert(vim.fn.writefile(vim.list({ 'second' }), root .. '/second.txt') == 0)
  vim.command('filetype on')

  assert(require('vfiler').start(root, {
    options = {
      layout = 'none',
      columns = 'name',
      new = true,
      session = 'none',
      preview = { layout = 'floating', delay = 1000 },
    },
  }))
  filer = assert(VFiler.get(vim.fn.bufnr()))
  local view = filer._view
  local context = filer._context

  local function move_to(name)
    view:move_cursor(root .. '/' .. name)
    vim.command('doautocmd <nomodeline> CursorMoved')
  end

  local function check_popup(text)
    local preview = assert(context.in_preview.preview)
    assert(preview.opened)
    local winid = preview._window:id()
    assert(vim.fn.popup_getpos(winid).visible == 1)
    local lines = compat.list.from(vim.fn.getbufline(vim.fn.winbufnr(winid), 1))
    assert(lines[1] == text, 'unexpected preview text: ' .. tostring(lines[1]))
    assert(vim.fn.win_getid() == view:winid())
    return winid
  end

  move_to('first.txt')
  filer:do_action(actions.toggle_auto_preview)
  check_popup('first')

  move_to('second.txt')
  local auto_popup = check_popup('second')
  move_to('directory/')
  assert(not context.in_preview.preview.opened)
  assert(vim.fn.popup_getpos(auto_popup).visible ~= 1)
  filer:do_action(actions.toggle_auto_preview)

  move_to('first.txt')
  filer:do_action(actions.toggle_preview)
  local manual_popup = check_popup('first')
  move_to('second.txt')
  assert(context.in_preview.preview == nil)
  assert(vim.fn.popup_getpos(manual_popup).visible ~= 1)

  move_to('first.txt')
  config.configs.hook.read_preview_file = function()
    return { 'hook first', 'hook second' }, 'text'
  end
  filer:do_action(actions.toggle_preview)
  local hook_popup = check_popup('hook first')
  local bufnr = vim.fn.winbufnr(hook_popup)
  local lines = compat.list.from(vim.fn.getbufline(bufnr, 1, '$'))
  assert(#lines == 2 and lines[2] == 'hook second')
  assert(vim.fn.getbufvar(bufnr, '&filetype') == 'text')
  filer:do_action(actions.toggle_preview)

  config.configs.hook.read_preview_file = function()
    error('preview hook failed')
  end
  filer:do_action(actions.toggle_preview)
  check_popup('"first.txt" could not be opened.')
end, debug.traceback)

config.configs.hook.read_preview_file = original_hook
if filer then
  local preview = filer._context.in_preview.preview
  if preview then
    preview:close()
  end
  filer:wipeout()
end
vim.fn.delete(root, 'rf')
assert(ok, err)
