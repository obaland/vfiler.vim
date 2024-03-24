local core = require('vfiler/libs/core')

local VFiler = require('vfiler/vfiler')

local M = {}

local function action_update_status(vfiler, context, view, path)
  local item = view:itemof(path)
  if not item then
    return
  end
  view:git_status_async(item.parent.path, function(v)
    v:redraw()
  end)
end

function M.update_file(bufnr, group, event)
  local vfilers = VFiler.get_visible_in_tabpage(0)
  if #vfilers == 0 then
    return
  end
  local path = core.path.normalize(vim.fn.bufname(bufnr))
  for _, vfiler in ipairs(vfilers) do
    vfiler:do_action(action_update_status, path)
  end
end

return M
