local cursor = require('vfiler/actions/cursor')
local u = require('tests/utility')

describe('cursor actions', function()
  local vfiler = u.vfiler.start(u.vfiler.generate_options())
  local action_sequence = {
    move_cursor_down = cursor.move_cursor_down,
    move_cursor_up = cursor.move_cursor_up,
    move_cursor_bottom = cursor.move_cursor_bottom,
    move_cursor_top = cursor.move_cursor_top,
    loop_cursor_up = cursor.loop_cursor_up,
    loop_cursor_down = cursor.loop_cursor_down,
  }
  for name, action in ipairs(action_sequence) do
    it(name, function()
      u.vfiler.do_action(vfiler, action)
    end)
  end
end)
