local basic = require('vfiler/actions/basic')
local u = require('tests/utility')

local configs = {
  options = u.vfiler.generate_options(),
}

local function desc(action_name, vfiler)
  return ('%s root:%s'):format(action_name, vfiler._context.root.path)
end

describe('basic actions', function()
  local vfiler = u.vfiler.start(configs)
  it(desc('open tree recursive', vfiler), function()
    local view = vfiler._view
    local init_lnum = configs.options.header and 2 or 1

    local item
    for lnum = init_lnum, view:num_lines() do
      item = view:get_item(lnum)
      if item.is_directory then
        view:move_cursor(item.path)
        break
      end
    end
    u.vfiler.do_action(vfiler, basic.open_tree_recursive)
    assert.is_true(item.opened)
  end)
  vfiler:quit(true)
end)
