local core = require('vfiler/libs/core')
local a = require('vfiler/actions/open')
local u = require('tests/utilities')

local configs = {
  options = u.vfiler.generate_options(),
}

describe('open actions', function()
  local vfiler = u.vfiler.start(configs)
  it(u.vfiler.desc('open by tabpage', vfiler), function()
    local view = vfiler._view
    core.cursor.move(u.int.random(2, view:num_lines()))
    vfiler:do_action(a.open_by_tabpage)
  end)
  vfiler:quit(true)
end)
