local a = require('vfiler/actions/open')
local u = require('tests/utility')

local configs = {
  options = u.vfiler.generate_options(),
}

describe('open actions', function()
  local vfiler = u.vfiler.start(configs)
  it(u.vfiler.desc('open', vfiler), function()
    local view = vfiler._view
    local init_lnum = configs.options.header and 2 or 1

    -- open directory
    for lnum = init_lnum, view:num_lines() do
      local item = view:get_item(lnum)
      if item.type == 'directory' then
        view:move_cursor(item.path)
        break
      end
    end
    u.vfiler.do_action(vfiler, a.open)

    -- open file
    for lnum = init_lnum, view:num_lines() do
      local item = view:get_item(lnum)
      if item.type ~= 'directory' then
        view:move_cursor(item.path)
        break
      end
    end
    u.vfiler.do_action(vfiler, a.open)
  end)
  vfiler:quit(true)
end)
