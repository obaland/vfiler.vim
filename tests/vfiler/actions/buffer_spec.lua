local buffer = require('vfiler/actions/buffer')
local u = require('tests/utility')
local VFiler = require('vfiler/vfiler')

local configs = {
  options = u.vfiler.generate_options(),
}

local function desc(action_name, vfiler)
  return ('%s root:%s'):format(action_name, vfiler._context.root.path)
end

describe('buffer actions', function()
  describe('Control buffer', function()
    local vfiler = u.vfiler.start(configs)

    it(desc('redraw', vfiler), function()
      u.vfiler.do_action(vfiler, buffer.redraw)
    end)

    it(desc('reload', vfiler), function()
      u.vfiler.do_action(vfiler, buffer.reload)
    end)

    it(desc('switch_to_filer', vfiler), function()
      u.vfiler.do_action(vfiler, buffer.switch_to_filer)
      u.vfiler.do_action(vfiler, buffer.sync_with_current_filer)
      local newfiler = VFiler.get_current()
      newfiler:quit(true)
    end)
  end)
end)
