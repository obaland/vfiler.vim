local core = require('vfiler/libs/core')
local a = require('vfiler/actions/open')
local u = require('tests/utilities')

describe('open actions', function()
  local layouts = {
    'none', 'right', 'left', 'top', 'bottom', 'tab', 'floating'
  }
  for _, layout in ipairs(layouts) do
    local configs = {
      options = u.vfiler.generate_options(),
    }
    configs.options.layout = layout
    local vfiler = u.vfiler.start(configs)
    assert.is_not_nil(vfiler)

    local view = vfiler._view
    assert.is_not_nil(view)
    local lnum = u.int.random(2, view:num_lines())
    local target = view:get_item(lnum)
    if target then
      core.cursor.move(lnum)
      local message = ('open by split [layout:%s] (%s)'):format(layout, target.path)
      it(u.vfiler.desc(message, vfiler), function()
        vfiler:do_action(a.open_by_split)
      end)
    end
    vfiler:quit(true)
  end
end)
