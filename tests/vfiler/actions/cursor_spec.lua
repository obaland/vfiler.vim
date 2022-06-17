local a = require('vfiler/actions/cursor')
local u = require('tests/utility')

describe('cursor actions', function()
  local vfiler = u.vfiler.start(u.vfiler.generate_options())
  local action_sequence = {
    move_cursor_down = a.move_cursor_down,
    move_cursor_down_sibling = a.move_cursor_down_sibling,
    move_cursor_up = a.move_cursor_up,
    move_cursor_up_sibling = a.move_cursor_up_sibling,
    move_cursor_bottom = a.move_cursor_bottom,
    move_cursor_bottom_sibling = a.move_cursor_bottom_sibling,
    move_cursor_top = a.move_cursor_top,
    move_cursor_top_sibling = a.move_cursor_top_sibling,
    loop_cursor_up = a.loop_cursor_up,
    loop_cursor_down = a.loop_cursor_down,
    loop_cursor_up_sibling = a.loop_cursor_up_sibling,
    loop_cursor_down_sibling = a.loop_cursor_down_sibling,
  }
  for name, action in pairs(action_sequence) do
    it(u.vfiler.desc(name, vfiler), function()
      vfiler:do_action(action)
    end)
  end
end)
