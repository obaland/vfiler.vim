local vim = require('vfiler/libs/vim')
local buffer = require('vfiler/actions/buffer')

local M = {}

function M.latest_update(vfiler, context, view)
  local root = context.root
  if vim.fn.getftime(root.path) > root.time then
    vfiler:do_action(buffer.reload)
    return
  end

  for item in view:walk_items() do
    if item.is_directory then
      if vim.fn.getftime(item.path) > item.time then
        vfiler:do_action(buffer.reload)
        return
      end
    end
  end
end

function M.close_floating(vfiler, context, view)
  if view:type() == 'floating' then
    view:close()
  end
end

return M
