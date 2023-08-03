local a = require('vfiler/actions/select')
local u = require('tests/utilities')

describe('select actions', function()
  u.randomseed()
  describe('Select', function()
    local vfiler = u.vfiler.start(u.vfiler.generate_options())
    local view = vfiler._view

    it(u.vfiler.desc('toggle_select', vfiler), function()
      vfiler:do_action(a.toggle_select)
      local current = view:get_item()
      assert.is_not_nil(current, 'line: ' .. vim.fn.line('.'))
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
end)
