local core = require('vfiler/libs/core')
local fs = require('vfiler/libs/filesystem')
local clipboard = require('vfiler/clipboard')
local cmdline = require('vfiler/libs/cmdline')
local VFiler = require('vfiler/vfiler')
local file_actions = require('vfiler/actions/file_operation')
local directory_actions = require('vfiler/actions/directory')
local open_actions = require('vfiler/actions/open')
local cursor_actions = require('vfiler/actions/cursor')
local preview_actions = require('vfiler/actions/preview')
local utils = require('vfiler/actions/utilities')

describe('actions with no visible items', function()
  local temp, root, filer, context, view, restore

  local function replace(target, key, value)
    local original = target[key]
    target[key] = value
    table.insert(restore, function()
      target[key] = original
    end)
    return original
  end

  local function start(hidden_only)
    if hidden_only then
      vim.fn.writefile({ 'HIDDEN' }, root .. '/.hidden')
    end
    assert.is_true(require('vfiler').start(root, {
      options = {
        new = true,
        header = false,
        columns = 'name',
        session = 'none',
        show_hidden_files = false,
        git = { enabled = false },
        preview = { layout = 'right', width = 20, height = 10 },
      },
    }))
    filer = VFiler.get(vim.fn.bufnr())
    context, view = filer._context, filer._view
  end

  local function assert_empty()
    assert.is_nil(view:get_item())
    assert.are.equal(0, view:num_lines())
  end

  before_each(function()
    restore, filer, context, view = {}, nil, nil, nil
    clipboard.clear()
    temp = vim.fn.tempname()
    root = core.path.join(temp, 'root')
    vim.fn.mkdir(root, 'p')
  end)

  after_each(function()
    for i = #restore, 1, -1 do
      restore[i]()
    end
    if context and context.in_preview.preview then
      context.in_preview.preview:close()
    end
    if filer then
      filer:wipeout()
    end
    clipboard.clear()
    vim.fn.delete(temp, 'rf')
  end)

  local no_item_actions = {
    { 'open', open_actions.open },
    { 'open_by_choose', open_actions.open_by_choose },
    { 'open_by_choose_or_cd', open_actions.open_by_choose_or_cd },
    { 'open_by_split', open_actions.open_by_split },
    { 'open_by_tabpage', open_actions.open_by_tabpage },
    { 'open_by_vsplit', open_actions.open_by_vsplit },
    { 'open_tree', directory_actions.open_tree },
    { 'open_tree_recursive', directory_actions.open_tree_recursive },
    { 'close_tree', directory_actions.close_tree },
    {
      'move_cursor_bottom_sibling',
      cursor_actions.move_cursor_bottom_sibling,
    },
    { 'move_cursor_down_sibling', cursor_actions.move_cursor_down_sibling },
    { 'move_cursor_top_sibling', cursor_actions.move_cursor_top_sibling },
    { 'move_cursor_up_sibling', cursor_actions.move_cursor_up_sibling },
    { 'loop_cursor_up_sibling', cursor_actions.loop_cursor_up_sibling },
    { 'loop_cursor_down_sibling', cursor_actions.loop_cursor_down_sibling },
  }

  for _, mode in ipairs({
    { name = 'empty directory', hidden = false },
    { name = 'hidden files only', hidden = true },
  }) do
    describe(mode.name, function()
      for _, case in ipairs(no_item_actions) do
        it(case[1] .. ' does nothing without a target', function()
          start(mode.hidden)
          assert_empty()
          local windows, tabs = vim.fn.winnr('$'), vim.fn.tabpagenr('$')
          local path = context.root.path
          filer:do_action(case[2])
          assert_empty()
          assert.is_true(context.root.opened)
          assert.are.equal(path, context.root.path)
          assert.are.equal(windows, vim.fn.winnr('$'))
          assert.are.equal(tabs, vim.fn.tabpagenr('$'))
        end)
      end

      it('creates a directory in the root', function()
        start(mode.hidden)
        assert_empty()
        replace(cmdline, 'input', function()
          return 'created'
        end)
        filer:do_action(file_actions.new_directory)
        assert.are.equal(1, vim.fn.isdirectory(root .. '/created'))
        assert.are.equal(
          core.path.normalize(root .. '/created'),
          view:get_item().path
        )
      end)

      it('creates a file in the root', function()
        start(mode.hidden)
        assert_empty()
        replace(cmdline, 'input', function()
          return 'created.txt'
        end)
        filer:do_action(file_actions.new_file)
        assert.are.equal(1, vim.fn.filereadable(root .. '/created.txt'))
        assert.are.equal(root .. '/created.txt', view:get_item().path)
      end)

      for _, move in ipairs({ false, true }) do
        local action_name = move and 'moves' or 'copies'
        it(action_name .. ' clipboard contents into the root', function()
          local source = core.path.join(temp, 'source.txt')
          vim.fn.writefile({ 'SOURCE' }, source)
          local item = require('vfiler/items/file').new(fs.stat(source))
          if move then
            clipboard.move_to_clipboard({ item })
          else
            clipboard.copy_to_clipboard({ item })
          end
          start(mode.hidden)
          assert_empty()
          filer:do_action(file_actions.paste)
          assert.are.same(
            { 'SOURCE' },
            vim.fn.readfile(root .. '/source.txt')
          )
          assert.are.equal(move and 0 or 1, vim.fn.filereadable(source))
          assert.are.equal(root .. '/source.txt', view:get_item().path)
        end)
      end

      for _, name in ipairs({ 'toggle_preview', 'toggle_auto_preview' }) do
        it(name .. ' leaves the preview closed', function()
          start(mode.hidden)
          assert_empty()
          local windows = vim.fn.winnr('$')
          filer:do_action(preview_actions[name])
          assert.is_false(context.in_preview.preview.opened)
          assert.are.equal(windows, vim.fn.winnr('$'))
        end)
      end

      it('does not bookmark a nonexistent item', function()
        local Bookmark = require('vfiler/extensions/bookmark')
        local calls = 0
        replace(Bookmark, 'add', function()
          calls = calls + 1
        end)
        start(mode.hidden)
        assert_empty()
        filer:do_action(require('vfiler/actions/bookmark').add_bookmark)
        assert.are.equal(0, calls)
      end)

      it('changes sort order while keeping an empty view', function()
        local Menu = require('vfiler/extensions/menu')
        replace(Menu, 'new', function(f, _, options)
          return {
            start = function()
              f:do_action(options.on_selected, 'size')
            end,
          }
        end)
        start(mode.hidden)
        assert_empty()
        filer:do_action(require('vfiler/actions/view').change_sort)
        assert.are.equal('size', context.options.sort)
        assert_empty()
      end)
    end)
  end

  it('opens a normal file when a target is visible', function()
    vim.fn.writefile({ 'CONTENT' }, root .. '/file.txt')
    start()
    filer:do_action(open_actions.open)
    assert.are.equal(root .. '/file.txt', vim.fn.expand('%:p'))
    assert.are.same(
      { 'CONTENT' },
      vim.api.nvim_buf_get_lines(0, 0, -1, false)
    )
  end)

  for _, name in ipairs({ 'open_tree', 'open_tree_recursive' }) do
    it(name .. ' opens an empty last directory', function()
      vim.fn.mkdir(root .. '/last')
      start()
      filer:do_action(directory_actions[name])
      assert.is_true(view:get_item().opened)
      assert.are.equal(
        core.path.normalize(root .. '/last'),
        view:get_item().path
      )
    end)
  end

  it('closes an existing preview after the last file disappears', function()
    vim.fn.writefile({ 'CONTENT' }, root .. '/file.txt')
    start()
    local windows = vim.fn.winnr('$')
    filer:do_action(preview_actions.toggle_auto_preview)
    local preview = context.in_preview.preview
    assert.is_true(preview.opened)
    vim.fn.delete(root .. '/file.txt')
    filer:do_action(require('vfiler/actions/buffer').reload_all_dir)
    assert_empty()
    filer:do_action(utils.open_preview)
    assert.is_false(preview.opened)
    assert.are.equal(windows, vim.fn.winnr('$'))
  end)

  it('switches drives without requiring a selected item', function()
    start()
    assert_empty()
    local target = core.path.join(temp, 'drive-target')
    vim.fn.mkdir(target)
    local Menu = require('vfiler/extensions/menu')
    local drive = 'drive-target'
    if core.is_windows then
      drive = core.path.root(root) == 'Z:/' and 'Y:/' or 'Z:/'
      local original = core.path.is_directory
      replace(core.path, 'is_directory', function(path)
        if path:match('^%a:/$') then
          return path == drive
        end
        return original(path)
      end)
    else
      replace(vim.fn, 'glob', function()
        return { target }
      end)
    end
    replace(context, 'switch_drive', function(self)
      return self:switch(target)
    end)
    replace(Menu, 'new', function(f, _, options)
      return {
        start = function()
          f:do_action(options.on_selected, drive)
        end,
      }
    end)
    filer:do_action(directory_actions.switch_to_drive)
    assert.are.equal(core.path.normalize(target), context.root.path)
    assert_empty()
  end)
end)
