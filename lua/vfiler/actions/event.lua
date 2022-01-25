local vim = require('vfiler/libs/vim')

local M = {}

function M.latest_update(vfiler, context, view)
  local root = context.root
  if vim.fn.getftime(root.path) > root.time then
    M.reload(vfiler, context, view)
    return
  end

  for item in view:walk_items() do
    if item.isdirectory then
      if vim.fn.getftime(item.path) > item.time then
        M.reload(vfiler, context, view)
        return
      end
    end
  end
end

return M
