local vim = require('vfiler/libs/vim')

local M = {}

--- Status string
---@param context table
---@param view table
function M.status(context, view)
  local options = context.options
  local offset = options.header and 1 or 0
  local item = view:get_item()
  if not item then
    return vim.dict({})
  end
  -- NOTE: Convert to 'dict' type for vim.
  return vim.dict({
    bufnr = view:bufnr(),
    root = vim.fn.fnamemodify(context.root.path, ':~'):gsub('\\', '/'),
    num_items = vim.fn.line('$') - offset,
    current_item = vim.dict({
      number = vim.fn.line('.') - offset,
      name = item.name,
      path = item.path,
      size = item.size,
      time = item.time,
      type = item.type,
      mode = item.mode,
      link = item.link,
    }),
    options = vim.dict({
      width = options.width,
      height = options.height,
    }),
  })
end

return M
