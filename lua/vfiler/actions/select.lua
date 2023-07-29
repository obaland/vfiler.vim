local M = {}

function M.clear_selected_all(vfiler, context, view)
  for _, item in ipairs(view:selected_items()) do
    item.selected = false
  end
  view:redraw()
end

function M.toggle_select(vfiler, context, view)
  local lnum = vim.fn.line('.')
  local item = view:get_item(lnum)
  if item then
    item.selected = not item.selected
    view:redraw_line(lnum)
  end
end

function M.toggle_select_all(vfiler, context, view)
  for item in view:walk_items() do
    if item ~= context.root then
      item.selected = not item.selected
    end
  end
  view:redraw()
end

return M
