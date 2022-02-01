local vim = require('vfiler/libs/vim')
local action_basic = require('vfiler/actions/basic')

local M = {}

function M.latest_update(vfiler, context, view)
  local root = context.root
  if vim.fn.getftime(root.path) > root.time then
    vfiler:do_action(action_basic.reload)
    return
  end

  for item in view:walk_items() do
    if item.is_directory then
      if vim.fn.getftime(item.path) > item.time then
        vfiler:do_action(action_basic.reload)
        return
      end
    end
  end
end

return M
