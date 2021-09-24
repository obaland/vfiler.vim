local column_collection = require 'vfiler/columns/collection'
local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local HeaderColumn = require 'vfiler/columns/header'

local View = {}
View.__index = View

function View.new(configs)
  local columns = {}
  for _, cname in ipairs(vim.fn.split(configs.columns, ',')) do
    local column = column_collection.get(cname)
    if column then
      table.insert(columns, column)
    else
      core.warning(string.format('"%s" is not a valid column.', cname))
    end
  end
  if #columns <= 0 then
    core.error(
      string.format('There are no valid columns. (%s)', configs.columns)
    )
    return nil
  end

  return setmetatable({
    _header_column = HeaderColumn.new(),
    _columns = columns,
    }, View)
end

function View:draw(context)
  -- syntax and highlight command
  local syntaxes = {
    'silent! syntax clear'
  }
  local highlights = {
    'silent! highlight clear'
  }

  core.concat_list(syntaxes, self._header_column:syntaxes())
  core.concat_list(highlights, self._header_column:highlights())
  for _, column in pairs(self._columns) do
    core.concat_list(syntaxes, column:syntaxes())
    core.concat_list(highlights, column:highlights())
  end
  vim.commands(syntaxes)
  vim.commands(highlights)

  self:_draw(context)
end

function View:redraw(context)
  self:_draw(context)
end

function View:_calculate_widths(context, winwidth)
  local widths = {}
  local variable_columns = {}
  for i, column in ipairs(self._columns) do
    local width = 0
    if column.variable then
      -- calculate later
      table.insert(variable_columns, {index = i, object = column})
    else
      width = column:get_width(context, winwidth)
      winwidth = winwidth - width
    end
    table.insert(widths, width)
  end

  -- decide variable column width
  for _, column in ipairs(variable_columns) do
    local width = column:get_width(context, winwidth)
    winwidth = winwidth - width
    widths[column.index] = width
  end

  return widths
end

function View:_draw(context)
  local winwidth = vim.fn.winwidth(0)
  if vim.get_win_option_boolean('number') or
    vim.get_win_option_boolean('relativenumber') then
    winwidth = winwidth - vim.get_win_option_value('numberwidth')
  end
  winwidth = winwidth - vim.get_win_option_value('foldcolumn')

  local column_widths = self:_calculate_widths(context, winwidth)
  local lines = {
    self._header_column:to_line(context, 1),
  }
  for i = 1, #context.items do
    local line = ''
    local lnum = i + 1 -- +1 for header line
    for j, column in ipairs(self._columns) do
      line = line .. column:to_line(context, lnum, column_widths[j])
    end
    table.insert(lines, line)
  end

  local saved_view = vim.fn.winsaveview()

  vim.set_buf_option('modifiable', true)
  vim.set_buf_option('readonly', false)
  vim.command('silent %delete _')
  vim.fn.setline(1, vim.convert_list(lines))
  vim.set_buf_option('modifiable', false)
  vim.set_buf_option('readonly', true)

  vim.fn.winrestview(saved_view)
end

return View
