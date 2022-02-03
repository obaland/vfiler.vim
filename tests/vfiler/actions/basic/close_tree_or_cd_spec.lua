local core = require('vfiler/libs/core')
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
  it(desc('close_tree_or_cd', vfiler), function()
    local root = vfiler._context.root
    local parent_path = core.path.parent(root.path)
    u.vfiler.do_action(vfiler, basic.close_tree_or_cd)
    root = vfiler._context.root
    assert.equal(parent_path, root.path)
  end)
  vfiler:quit(true)
end)
