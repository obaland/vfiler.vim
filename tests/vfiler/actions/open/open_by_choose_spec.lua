local core = require('vfiler/libs/core')
local a = require('vfiler/actions/open')
local u = require('tests/utilities')

local configs = {
  options = u.vfiler.generate_options(),
}

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

    local message = ('open by choose (%s)'):format(layout)
    it(u.vfiler.desc(message, vfiler), function()
      local view = vfiler._view
      core.cursor.move(u.int.random(2, view:num_lines()))
      vfiler:do_action(a.open_by_choose)
    end)
    vfiler:quit(true)
  end
end)
