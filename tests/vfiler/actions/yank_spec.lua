local a = require('vfiler/actions/yank')
local u = require('tests/utility')

local configs = {
  options = u.vfiler.generate_options(),
}

describe('yank actions', function()
  local vfiler = u.vfiler.start(configs)
  it(u.vfiler.desc('yank_path', vfiler), function()
    u.vfiler.do_action(vfiler, a.yank_path)
    -- TODO:
  end)

  it(u.vfiler.desc('yank_name', vfiler), function()
    u.vfiler.do_action(vfiler, a.yank_name)
    -- TODO:
  end)
  vfiler:quit(true)
end)
