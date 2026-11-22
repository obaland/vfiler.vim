local utils = require('vfiler/actions/utilities')
local vim = require('vfiler/libs/vim')

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
  if preview.line == line then
    preview:cancel_pending()
    return
  end

  if in_preview.once then
    utils.close_preview(vfiler, context, view)
    preview.line = line
    return
  end

  local item = view:get_item(line)
  if not (item and item.type == 'file') then
    utils.open_preview(vfiler, context, view)
    return
  end

  local path = item.path
  preview:defer_open(function()
    if
      in_preview.preview ~= preview
      or in_preview.once
      or vim.fn.win_getid() ~= view:winid()
      or vim.fn.line('.') ~= line
    then
      return
    end

    local current = view:get_item(line)
    if current and current.path == path then
      utils.open_preview(vfiler, context, view)
    end
  end)
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
    in_preview.preview =
      require('vfiler/preview').new(context.options.preview)
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
    in_preview.preview =
      require('vfiler/preview').new(context.options.preview)
    in_preview.once = true
  end
  utils.open_preview(vfiler, context, view)
end

function M.scroll_down_preview(vfiler, context, view)
  local in_preview = context.in_preview
  local preview = in_preview.preview
  if not preview then
    return
  end
  preview:scroll_down()
end

function M.scroll_up_preview(vfiler, context, view)
  local in_preview = context.in_preview
  local preview = in_preview.preview
  if not preview then
    return
  end
  preview:scroll_up()
end

return M
