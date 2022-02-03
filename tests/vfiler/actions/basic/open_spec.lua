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
  it(desc('open', vfiler), function()
    local view = vfiler._view
    local init_lnum = configs.options.header and 2 or 1

    -- open directory
    for lnum = init_lnum, view:num_lines() do
      local item = view:get_item(lnum)
      if item.is_directory then
        view:move_cursor(item.path)
        break
      end
    end
    u.vfiler.do_action(vfiler, basic.open)

    -- open file
    for lnum = init_lnum, view:num_lines() do
      local item = view:get_item(lnum)
      if not item.is_directory then
        view:move_cursor(item.path)
        break
      end
    end
    u.vfiler.do_action(vfiler, basic.open)
  end)
  vfiler:quit(true)
end)
