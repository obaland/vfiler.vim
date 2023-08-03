local utils = require('vfiler/actions/utilities')
local vim = require('vfiler/libs/vim')

local Preview = require('vfiler/preview')

local M = {}

function M.close_preview(vfiler, context, view)
  utils.close_preview(vfiler, context, view)
end

function M.preview_cursor_moved(vfiler, context, view)
  local in_preview = context.in_preview
  local preview = in_preview.preview
  if not preview then
    return
  end

  local line = vim.fn.line('.')
  if preview.line ~= line then
    if in_preview.once then
      utils.close_preview(vfiler, context, view)
    else
      utils.open_preview(vfiler, context, view)
    end
    preview.line = line
  end
end

function M.toggle_auto_preview(vfiler, context, view)
  local in_preview = context.in_preview
  local preview = in_preview.preview
  if preview and not in_preview.once then
    preview:close()
    view:redraw()
    in_preview.preview = nil
    return
  end

  if not preview then
    in_preview.preview = Preview.new(context.options.preview)
  end
  in_preview.once = false
  utils.open_preview(vfiler, context, view)
end

function M.toggle_preview(vfiler, context, view)
  local in_preview = context.in_preview
  if utils.close_preview(vfiler, context, view) then
    in_preview.preview = nil
    return
  end
  if not in_preview.preview then
    in_preview.preview = Preview.new(context.options.preview)
    in_preview.once = true
  end
  utils.open_preview(vfiler, context, view)
end

return M
