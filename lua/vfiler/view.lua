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
      core.warning(("'%s' is not a valid column."):format(cname))
    end
  end
  if #columns <= 0 then
    core.error(
      string.format('There are no valid columns. (%s)', configs.columns)
    )
    return nil
  end

  local object = setmetatable({
    _cache = {
      winwidth = 0,
    },
    _columns = columns,
    _header_column = HeaderColumn.new(),
    }, View)
  object:_apply_syntaxes()
  return object
end

function View:draw(context)
  local winwidth = vim.fn.winwidth(0) - 1 -- padding end
  if vim.get_win_option_boolean('number') or
    vim.get_win_option_boolean('relativenumber') then
    winwidth = winwidth - vim.get_win_option_value('numberwidth')
  end
  winwidth = winwidth - vim.get_win_option_value('foldcolumn')

  local cache = self._cache
  if cache.winwidth ~= winwidth or (not cache.column_params) then
    cache.column_params = self:_create_column_params(context, winwidth)
    cache.winwidth = winwidth
  end

  -- create text lines
  local lines = {self._header_column:get_text(context, 1)}
  for i = 2, #context.items do
    local line = ''
    local line_width = 0
    for j, column in ipairs(self._columns) do
      local param = cache.column_params[j]

      local column_width = param.width
      if column.variable then
        column_width = column_width + (param.start_pos - line_width - 1)
      end

      local text, width = column:get_text(context, i, column_width)
      line = line .. text
      line_width = line_width + width

      if column.stretch then
        -- Adjust to fit column end base position
        local padding = param.end_pos - line_width
        if padding > 0 then
          line = line .. (' '):rep(padding)
        end
      end
    end
    table.insert(lines, line)
  end

  -- set buffer lines
  local saved_view = vim.fn.winsaveview()

  vim.set_buf_option('modifiable', true)
  vim.set_buf_option('readonly', false)
  vim.command('silent %delete _')
  vim.fn.setline(1, vim.convert_list(lines))
  vim.set_buf_option('modifiable', false)
  vim.set_buf_option('readonly', true)

  vim.fn.winrestview(saved_view)
end

function View:_apply_syntaxes()
  -- syntax and highlight command
  local syntaxes = {}
  local highlights = {}

  core.concat_list(syntaxes, self._header_column:syntaxes())
  core.concat_list(highlights, self._header_column:highlights())
  for _, column in pairs(self._columns) do
    local column_syntaxes = column:syntaxes()
    if column_syntaxes then
      core.concat_list(syntaxes, column_syntaxes)
    end
    local column_highlights = column:highlights()
    if column_highlights then
      core.concat_list(highlights, column_highlights)
    end
  end
  vim.commands(syntaxes)
  vim.commands(highlights)
end

function View:_create_column_params(context, winwidth)
  local params = {}
  local variable_columns = {}
  local rest_width = winwidth

  for i, column in ipairs(self._columns) do
    local width = 0
    if column.variable then
      -- calculate later
      table.insert(variable_columns, {index = i, object = column})
    else
      width = column:get_width(context, rest_width)
    end
    table.insert(params, {width = width})
    rest_width = rest_width - width
  end

  -- decide variable column width
  if #variable_columns > 0 then
    local width_by_columns = math.floor(rest_width / #variable_columns)
    for _, column in ipairs(variable_columns) do
      params[column.index].width = column.object:get_width(
        context, width_by_columns
      )
    end
  end

  -- decide column base position
  local pos = 1
  for _, param in ipairs(params) do
    param.start_pos = pos
    if param.width > 0 then
      param.end_pos = param.start_pos + param.width - 1
      pos = param.end_pos + 1
    else
      param.end_pos = param.start_pos
      pos = param.end_pos
    end
  end
  return params
end

return View
