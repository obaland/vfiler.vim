local a = require('vfiler/actions/buffer')
local u = require('tests/utility')
local VFiler = require('vfiler/vfiler')

local configs = {
  options = u.vfiler.generate_options(),
}

describe('buffer actions', function()
  describe('Control buffer', function()
    local vfiler = u.vfiler.start(configs)

    it(u.vfiler.desc('redraw', vfiler), function()
      u.vfiler.do_action(vfiler, a.redraw)
    end)

    it(u.vfiler.desc('reload', vfiler), function()
      u.vfiler.do_action(vfiler, a.reload)
    end)

    it(u.vfiler.desc('switch_to_filer', vfiler), function()
      u.vfiler.do_action(vfiler, a.switch_to_filer)
      u.vfiler.do_action(vfiler, a.sync_with_current_filer)
      local newfiler = VFiler.get_current()
      newfiler:quit(true)
    end)
  end)
end)
