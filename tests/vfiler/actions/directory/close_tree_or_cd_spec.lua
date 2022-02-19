local core = require('vfiler/libs/core')
local a = require('vfiler/actions/directory')
local u = require('tests/utility')

local configs = {
  options = u.vfiler.generate_options(),
}

describe('directory actions', function()
  local vfiler = u.vfiler.start(configs)
  it(u.vfiler.desc('close_tree_or_cd', vfiler), function()
    local root = vfiler._context.root
    local parent_path = core.path.parent(root.path)
    vfiler:do_action(a.close_tree_or_cd)
    root = vfiler._context.root
    assert.equal(parent_path, root.path)
  end)
  vfiler:quit(true)
end)
