local core = require('vfiler/libs/core')
local basic = require('vfiler/actions/basic')
local u = require('tests/utility')
local VFiler = require('vfiler/vfiler')

local configs = {
  options = u.vfiler.generate_options(),
}
configs.options.new = true

local function desc(action_name, vfiler)
  return ('%s root:%s'):format(action_name, vfiler._context.root.path)
end

describe('basic actions', function()
  u.randomseed()
  describe('Control file', function()
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

    vfiler = u.vfiler.start(configs)
    it(desc('open by choose', vfiler), function()
      local view = vfiler._view
      core.cursor.move(u.int.random(2, view:num_lines()))
      u.vfiler.do_action(vfiler, basic.open_by_choose)
    end)

    vfiler = u.vfiler.start(configs)
    it(desc('open by split', vfiler), function()
      local view = vfiler._view
      core.cursor.move(u.int.random(2, view:num_lines()))
      u.vfiler.do_action(vfiler, basic.open_by_split)
    end)

    vfiler = u.vfiler.start(configs)
    it(desc('open by vsplit', vfiler), function()
      local view = vfiler._view
      core.cursor.move(u.int.random(2, view:num_lines()))
      u.vfiler.do_action(vfiler, basic.open_by_vsplit)
    end)

    vfiler = u.vfiler.start(configs)
    it(desc('open by tabpage', vfiler), function()
      local view = vfiler._view
      core.cursor.move(u.int.random(2, view:num_lines()))
      u.vfiler.do_action(vfiler, basic.open_by_tabpage)
    end)

    vfiler = u.vfiler.start(configs)
    it(desc('open and close tree', vfiler), function()
      local view = vfiler._view
      local init_lnum = configs.options.header and 2 or 1
      local num_lines = view:num_lines()
      assert(init_lnum < num_lines)

      -- open directory
      local item
      for lnum = init_lnum, view:num_lines() do
        item = view:get_item(lnum)
        if item.is_directory then
          view:move_cursor(item.path)
          break
        end
      end

      item = view:get_current()
      assert.is_true(item.is_directory)
      u.vfiler.do_action(vfiler, basic.open_tree)
      assert.is_true(item.opened, item.path)

      u.vfiler.do_action(vfiler, basic.close_tree)
      item = view:get_current()
      assert.is_false(item.opened, item.path)
    end)

    vfiler = u.vfiler.start(configs)
    it(desc('close_tree_or_cd', vfiler), function()
      local root = vfiler._context.root
      local parent_path = core.path.parent(root.path)
      u.vfiler.do_action(vfiler, basic.close_tree_or_cd)
      root = vfiler._context.root
      assert.equal(parent_path, root.path)
    end)

    vfiler = u.vfiler.start(configs)
    it(desc('open tree recursive', vfiler), function()
      local view = vfiler._view
      local init_lnum = configs.options.header and 2 or 1

      local item
      for lnum = init_lnum, view:num_lines() do
        item = view:get_item(lnum)
        if item.is_directory then
          view:move_cursor(item.path)
          break
        end
      end
      u.vfiler.do_action(vfiler, basic.open_tree_recursive)
      assert.is_true(item.opened)
    end)
  end)
end)
