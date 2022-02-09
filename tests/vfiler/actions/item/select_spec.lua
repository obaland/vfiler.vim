local item_a = require('vfiler/actions/item')
local u = require('tests/utility')

local function desc(action_name, vfiler)
  return ('%s root:%s'):format(action_name, vfiler._context.root.path)
end

describe('item actions', function()
  u.randomseed()
  describe('Select', function()
    local vfiler = u.vfiler.start(u.vfiler.generate_options())
    local view = vfiler._view

    it(desc('toggle_select', vfiler), function()
      u.vfiler.do_action(vfiler, item_a.toggle_select)
      local current = view:get_current()
      assert.is_not_nil(current, 'line: ' .. vim.fn.line('.'))
      assert.is_true(current.selected)
    end)

    it(desc('clear_select_all', vfiler), function()
      u.vfiler.do_action(vfiler, item_a.clear_selected_all)
      for item in vfiler._view:walk_items() do
        assert.is_false(item.selected)
      end
    end)

    it(desc('toggle_select_all', vfiler), function()
      u.vfiler.do_action(vfiler, item_a.toggle_select_all)
      for item in vfiler._view:walk_items() do
        assert.is_true(item.selected)
      end
    end)
  end)
end)
