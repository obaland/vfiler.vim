local a = require('vfiler/actions/view')
local u = require('tests/utility')

describe('view actions', function()
  u.randomseed()
  describe('Show hidden files', function()
    local vfiler = u.vfiler.start(u.vfiler.generate_options())

    it(u.vfiler.desc('show_hidden: ON', vfiler), function()
      u.vfiler.do_action(vfiler, a.toggle_show_hidden)
      -- TODO:
    end)
    it(u.vfiler.desc('show_hidden: OFF', vfiler), function()
      u.vfiler.do_action(vfiler, a.toggle_show_hidden)
      -- TODO:
    end)
  end)
end)
