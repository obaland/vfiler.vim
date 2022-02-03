local basic = require('vfiler/actions/basic')
local u = require('tests/utility')

describe('basic actions', function()
  describe('Cursor', function()
    local vfiler = u.vfiler.start(u.vfiler.generate_options())
    local action_sequence = {
      'move_cursor_down',
      'move_cursor_up',
      'move_cursor_bottom',
      'move_cursor_top',
      'loop_cursor_up',
      'loop_cursor_down',
    }
    for _, action in ipairs(action_sequence) do
      it(action, function()
        u.vfiler.do_action(vfiler, basic[action])
      end)
    end
  end)
end)
