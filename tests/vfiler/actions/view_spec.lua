local a = require('vfiler/actions/view')
local u = require('tests/utility')

local function find(view, target)
  for item in view:walk_items() do
    if item.name == target then
      return true
    end
  end
  return false
end

describe('view actions', function()
  u.randomseed()
  describe('Show hidden files', function()
    local options = u.vfiler.generate_options()
    options.show_hidden_files = false
    local vfiler, _, view = u.vfiler.start(options)
    local target = '.gitignore'

    it(u.vfiler.desc('show_hidden: ON', vfiler), function()
      vfiler:do_action(a.toggle_show_hidden)
      assert.is_true(find(view, target))
    end)
    it(u.vfiler.desc('show_hidden: OFF', vfiler), function()
      vfiler:do_action(a.toggle_show_hidden)
      assert.is_false(find(view, target))
    end)

    vfiler:quit(true)
  end)

  describe('Sort', function()
    local options = u.vfiler.generate_options()
    options.sort = 'name'
    local vfiler, context = u.vfiler.start(options)

    it(u.vfiler.desc('toggle_sort', vfiler), function()
      vfiler:do_action(a.toggle_sort)
      assert.is_equal('Name', context.options.sort)
      -- TODO:

      vfiler:do_action(a.toggle_sort)
      assert.is_equal('name', context.options.sort)
    end)

    it(u.vfiler.desc('change_sort', vfiler), function()
      vfiler:do_action(a.change_sort)
      assert.is_not_nil(context.extension)
      assert.is_equal('name', context.extension:get_item())

      -- quit window
      context.extension:quit()
      assert.is_nil(context.extension)
    end)

    vfiler:quit(true)
  end)
end)
