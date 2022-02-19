local a = require('vfiler/actions/directory')
local u = require('tests/utility')

local configs = {
  options = u.vfiler.generate_options(),
}

describe('directory actions', function()
  local vfiler = u.vfiler.start(configs)
  it(u.vfiler.desc('open and close tree', vfiler), function()
    local view = vfiler._view
    local init_lnum = configs.options.header and 2 or 1
    local num_lines = view:num_lines()
    assert(init_lnum < num_lines)

    -- open directory
    local item
    for lnum = init_lnum, view:num_lines() do
      item = view:get_item(lnum)
      if item.type == 'directory' then
        view:move_cursor(item.path)
        break
      end
    end

    item = view:get_current()
    assert.is_true(item.type == 'directory')
    vfiler:do_action(a.open_tree)
    assert.is_true(item.opened, item.path)

    vfiler:do_action(a.close_tree)
    item = view:get_current()
    assert.is_false(item.opened, item.path)
  end)
  vfiler:quit(true)
end)
