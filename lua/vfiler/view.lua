local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local View = {}
View.__index = View

local function create_buffer(bufname, options)
  -- Save swapfile option
  local swapfile = vim.get_buf_option_boolean('swapfile')
  vim.set_buf_option('swapfile', false)
  vim.command('silent edit ' .. bufname)
  vim.set_buf_option('swapfile', swapfile)

  -- Set buffer local options
  vim.set_buf_options {
    bufhidden = 'hide',
    buflisted = options.listed,
    buftype = 'nofile',
    filetype = 'vfiler',
    modifiable = false,
    modified = false,
    readonly = false,
    swapfile = false,
  }

  -- Set window local options
  if vim.fn.exists('&colorcolumn') == 1 then
    vim.set_win_option('colorcolumn', '')
  end
  if vim.fn.has('conceal') == 1 then
    if vim.get_win_option_value('conceallevel') < 2 then
      vim.set_win_option('conceallevel', 2)
    end
    vim.set_win_option('concealcursor', 'nvc')
  end

  vim.set_win_options {
    foldcolumn = '0',
    foldenable = false,
    list = false,
    number = false,
    spell = false,
    wrap = false,
  }
  return vim.fn.bufnr()
end

local function create_columns(columns)
  local collection = require 'vfiler/columns/collection'
  local objects = {}

  local cnames = vim.from_vimlist(vim.fn.split(columns, ','))
  for _, cname in ipairs(cnames) do
    local column = collection.get(cname)
    if column then
      table.insert(objects, column)
    else
      core.message.warning('"%s" is not a valid column.', cname)
    end
  end
  if #objects <= 0 then
    core.message.error('There are invalid columns. (%s)', columns)
    return nil
  end
  return objects
end

---@param bufname string
---@param options table
function View.new(bufname, options)
  local columns = create_columns(options.columns)
  if not columns then
    return nil
  end

  local bufnr = create_buffer(bufname, options)
  local object = setmetatable({
    bufname = bufname,
    bufnr = bufnr,
    show_hidden_files = options.show_hidden_files,
    _cache = {
      winwidth = 0,
    },
    _columns = columns,
    _items = {},
    }, View)
  object:_apply_syntaxes()
  return object
end

---Delete view object
function View:delete()
  if self.bufnr >= 0 then
    vim.command('silent bwipeout ' .. self.bufnr)
  end
  self.bufnr = -1
end

function View:displayed()
  return self:winnr() >= 0
end

function View:get_current()
  return self:get_item(vim.fn.line('.'))
end

---@param lnum number
function View:get_item(lnum)
  return self._items[lnum]
end

---Draw context contents
---@param context table
function View:draw(context)
  -- expand item list
  local root = context.root
  self._items = {root} -- header
  self:_expand_items(root.children)
  self:redraw()
end

---@param path string
function View:indexof(path)
  for i, item in ipairs(self._items) do
    if item.path == path then
      return i
    end
  end
  return 0
end

function View:num_lines()
  return #self._items
end

function View:open()
  vim.command('silent buffer ' .. self.bufnr)
end

function View:redraw()
  if self.bufnr ~= vim.fn.bufnr() then
    core.message.warning('Cannot draw because the buffer is different.')
    return
  end

  local winwidth = vim.fn.winwidth(0) - 1 -- padding end
  if vim.get_win_option_boolean('number') or
    vim.get_win_option_boolean('relativenumber') then
    winwidth = winwidth - vim.get_win_option_value('numberwidth')
  end
  winwidth = winwidth - vim.get_win_option_value('foldcolumn')

  local cache = self._cache
  if cache.winwidth ~= winwidth or (not cache.column_props) then
    cache.column_props = self:_create_column_props(winwidth)
    cache.winwidth = winwidth
  end

  -- create text lines
  local lines = {}
  for i, item in ipairs(self._items) do
    -- first line is the header line
    local line = i == 1 and self:_toheader(item) or self:_toline(item)
    table.insert(lines, line)
  end

  -- set buffer lines
  local saved_view = vim.fn.winsaveview()

  vim.set_buf_option('modifiable', true)
  vim.set_buf_option('readonly', false)
  vim.command('silent %delete _')
  vim.fn.setline(1, vim.to_vimlist(lines))
  vim.set_buf_option('modifiable', false)
  vim.set_buf_option('readonly', true)

  vim.fn.winrestview(saved_view)
end

function View:redraw_line(lnum)
  local item = self:get_item(lnum)
  -- first line is the header line
  local line = lnum == 1 and self:_toheader(item) or self:_toline(item)

  vim.set_buf_option('modifiable', true)
  vim.set_buf_option('readonly', false)
  vim.fn.setline(lnum, line)
  vim.set_buf_option('modifiable', false)
  vim.set_buf_option('readonly', true)
end

function View:selected_items()
  local selected = {}
  for _, item in ipairs(self._items) do
    if item.selected then
      table.insert(selected, item)
    end
  end
  if #selected == 0 then
    local lnum = vim.fn.line('.')
    if lnum ~= 1 then
      selected = {self:get_item(lnum)}
    end
  end
  return selected
end

function View:winnr()
  return vim.fn.bufwinnr(self.bufnr)
end

function View:_apply_syntaxes()
  local header_group = 'vfilerHeader'
  local syntaxes = {
    core.syntax.clear_command({header_group}),
    core.syntax.match_command(header_group, [[\%1l.*']]),
  }
  local highlights = {
    core.highlight.link_command(header_group, 'Statement'),
  }

  for _, column in pairs(self._columns) do
    local column_syntaxes = column:syntaxes()
    if column_syntaxes then
      core.list.extend(syntaxes, column_syntaxes)
    end
    local column_highlights = column:highlights()
    if column_highlights then
      core.list.extend(highlights, column_highlights)
    end
  end

  vim.commands(syntaxes)
  vim.commands(highlights)
end

function View:_create_column_props(winwidth)
  local props = {}
  local variable_columns = {}

  -- Subtract the space between columns
  local rest_width = winwidth - (#self._columns - 1)

  for i, column in ipairs(self._columns) do
    local width = 0
    if column.variable then
      -- calculate later
      table.insert(variable_columns, {index = i, object = column})
    else
      width = column:get_width(self._items, rest_width)
    end
    table.insert(props, {width = width})
    rest_width = rest_width - width
  end

  -- decide variable column width
  if #variable_columns > 0 then
    local width_by_columns = math.floor(rest_width / #variable_columns)
    for _, column in ipairs(variable_columns) do
      props[column.index].width = column.object:get_width(
        self._items, width_by_columns
      )
    end
  end

  local cumulative_width = 0
  for _, prop in ipairs(props) do
    cumulative_width = cumulative_width + prop.width
    prop.cumulative_width = cumulative_width
  end
  return props
end

function View:_expand_items(items)
  for _, item in ipairs(items) do
    local hidden_file = item.name:sub(1, 1) == '.'
    if self.show_hidden_files or not hidden_file then
      table.insert(self._items, item)
      if item.children and #item.children > 0 then
        self:_expand_items(item.children)
      end
    end
  end
end

---@param item table
function View:_toheader(item)
  return '[path] ' .. item.path
end

---@param item table
function View:_toline(item)
  local texts = {}
  local cumulative_width = 0
  for i, column in ipairs(self._columns) do
    local prop = self._cache.column_props[i]

    local cwidth = prop.width
    if column.variable then
      cwidth = cwidth + (prop.cumulative_width - cumulative_width)
    end

    local text, width = column:get_text(item, cwidth)
    cumulative_width = cumulative_width + width

    if column.stretch then
      -- Adjust to fit column end base position
      local padding = prop.cumulative_width - cumulative_width
      if padding > 0 then
        text = text .. (' '):rep(padding)
      end
    end
    table.insert(texts, text)
  end
  return table.concat(texts, ' ')
end

return View
