local a = require('vfiler/actions/yank')
local u = require('tests/utility')
local core = require('vfiler/libs/core')
local cursor = require('vfiler/actions/cursor')

local configs = {
  options = u.vfiler.generate_options(),
}

describe('yank actions', function()
  local vfiler = u.vfiler.start(configs)
  local view = vfiler._view
  local target = 'README.md'
  it(u.vfiler.desc('yank_path', vfiler), function()
    -- move to "README.md"
    while view:get_current().name ~= target do
      vfiler:do_action(cursor.move_cursor_down)
    end
    assert.is_equal(view:get_current().name, target)
    vfiler:do_action(a.yank_path)

    local expected = core.path.join(vim.fn.getcwd(), target)
    assert.is_equal(expected, vim.api.nvim_eval('@0'))
  end)

  it(u.vfiler.desc('yank_name', vfiler), function()
    vfiler:do_action(a.yank_name)
    assert.is_equal(target, vim.api.nvim_eval('@0'))
  end)
  vfiler:quit(true)
end)
