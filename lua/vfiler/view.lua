local vim = require 'vfiler/vim'

local View = {}
View.__index = View

function View.new(...)
  return setmetatable({
    }, View)
end

function View.draw(context)
  local lines = {}
  table.insert(lines, context.path)
  for _, item in ipairs(context.items) do
    table.insert(lines, item.name)
  end

  local saved_view = vim.fn.winsaveview()

  vim.set_buf_option('modifiable', true)
  vim.set_buf_option('readonly', false)
  vim.command('silent %delete _')
  vim.fn.setline(1, lines)
  vim.set_buf_option('modifiable', false)
  vim.set_buf_option('readonly', true)

  vim.fn.winrestview(saved_view)
end

return View
