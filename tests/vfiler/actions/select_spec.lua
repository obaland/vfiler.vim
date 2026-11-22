local a = require('vfiler/actions/select')
local core = require('vfiler/libs/core')
local u = require('tests/helper/utilities')
local VFiler = require('vfiler/vfiler')

describe('select actions', function()
  u.randomseed()
  describe('Select', function()
    local vfiler = u.vfiler.start(u.vfiler.generate_options())
    local view = vfiler._view

    it(u.vfiler.desc('toggle_select', vfiler), function()
      vfiler:do_action(a.toggle_select)
      local current = view:get_item()
      assert.is_not_nil(current)
      assert.is_true(current.selected)
    end)

    it(u.vfiler.desc('clear_select_all', vfiler), function()
      vfiler:do_action(a.clear_selected_all)
      for item in vfiler._view:walk_items() do
        assert.is_false(item.selected)
      end
    end)

    it(u.vfiler.desc('toggle_select_all', vfiler), function()
      vfiler:do_action(a.toggle_select_all)
      for item in vfiler._view:walk_items() do
        if item ~= vfiler._context.root then
          assert.is_true(item.selected)
        end
      end
    end)
  end)

  describe('clear selected marks', function()
    local filer, view, root
    local clock = os.time
    local custom_column = 'vfiler/columns/test_selection_state'

    local function start(header, columns)
      assert.is_true(require('vfiler').start(root, {
        options = {
          columns = columns or 'icon,name,time',
          header = header,
          layout = 'right',
          new = true,
          width = 60,
        },
      }))
      filer = VFiler.get(vim.fn.bufnr())
      view = filer._view
    end

    local function select_file(name)
      local path = core.path.join(root, name)
      view:move_cursor(path)
      filer:do_action(a.toggle_select)
      return view:indexof(path)
    end

    local function read_lines()
      return vim.api.nvim_buf_get_lines(view:bufnr(), 0, -1, false)
    end

    before_each(function()
      filer = nil
      root = vim.fn.tempname()
      assert.are.equal(1, vim.fn.mkdir(root, 'p'))
      for _, name in ipairs({ 'a.txt', 'b.txt', 'c.txt', 'd.txt', 'e.txt' }) do
        assert.are.equal(0, vim.fn.writefile({}, core.path.join(root, name)))
      end
    end)

    after_each(function()
      os.time = clock
      package.preload[custom_column] = nil
      package.loaded[custom_column] = nil
      if filer then
        filer:wipeout()
      end
      vim.fn.delete(root, 'rf')
    end)

    for _, header in ipairs({ true, false }) do
      it('restores unselected lines with header ' .. tostring(header), function()
        start(header)
        local unselected = read_lines()
        local first = select_file('a.txt')
        local last = select_file('e.txt')
        local selected = read_lines()
        assert.not_equal(unselected[first], selected[first])
        assert.not_equal(unselected[last], selected[last])

        filer:do_action(a.clear_selected_all)

        assert.are.same(unselected, read_lines())
        assert.are.equal(last, vim.fn.line('.'))
        assert.is_false(view:get_item(first).selected)
        assert.is_false(view:get_item(last).selected)
      end)
    end

    it('uses the current window width when clearing a selection', function()
      start(true)
      select_file('a.txt')
      local lnum = view:indexof(core.path.join(root, 'b.txt'))
      local before = read_lines()
      vim.api.nvim_win_set_width(view:winid(), 28)

      filer:do_action(a.clear_selected_all)

      local after = read_lines()
      assert.not_equal(before[lnum], after[lnum])
      view:redraw()
      assert.are.same(after, read_lines())
    end)

    it('updates time highlighting on unselected lines when it expires', function()
      start(true)
      local now = 1000000000
      os.time = function()
        return now
      end
      local path = core.path.join(root, 'c.txt')
      view:itemof(path).time = now - 86400 + 1
      view:redraw()
      local lnum = view:indexof(path)
      local before = read_lines()[lnum]
      select_file('a.txt')
      now = now + 2

      filer:do_action(a.clear_selected_all)

      local after = read_lines()[lnum]
      assert.not_equal(before, after)
      view:redraw()
      assert.are.equal(after, read_lines()[lnum])
    end)

    it('refreshes custom columns that depend on other rows', function()
      package.preload[custom_column] = function()
        return {
          new = function()
            local column = require('vfiler/columns/column').new()
            function column:get_width()
              return 1
            end
            function column:to_text(item)
              for _, sibling in ipairs(item.parent.children) do
                if sibling.selected then
                  return { string = 'Y', width = 1 }
                end
              end
              return { string = 'N', width = 1 }
            end
            return column
          end,
        }
      end

      start(true, 'test_selection_state,name')
      select_file('a.txt')
      view:redraw()
      local lnum = view:indexof(core.path.join(root, 'b.txt'))
      assert.are.equal('Y', read_lines()[lnum]:sub(1, 1))

      filer:do_action(a.clear_selected_all)

      assert.are.equal('N', read_lines()[lnum]:sub(1, 1))
    end)
  end)
end)
