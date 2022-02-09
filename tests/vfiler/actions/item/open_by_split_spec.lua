local core = require('vfiler/libs/core')
local item_a = require('vfiler/actions/item')
local u = require('tests/utility')

local configs = {
  options = u.vfiler.generate_options(),
}

local function desc(action_name, vfiler)
  return ('%s root:%s'):format(action_name, vfiler._context.root.path)
end

describe('item actions', function()
  local vfiler = u.vfiler.start(configs)
  it(desc('open by split', vfiler), function()
    local view = vfiler._view
    core.cursor.move(u.int.random(2, view:num_lines()))
    u.vfiler.do_action(vfiler, item_a.open_by_split)
  end)
  vfiler:quit(true)
end)
