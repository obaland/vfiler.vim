local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local View = {}
View.__index = View

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
  local object = setmetatable({
    bufnr = -1,
    _bufname = bufname,
  }, View)
  object:_reset(options)
  return object
end

function View:create()
  self.bufnr = self:_create_buffer()
  self:_apply_syntaxes()
  return self.bufnr
end

---Delete view object
function View:delete()
  if self.bufnr >= 0 then
    vim.command('silent bwipeout ' .. self.bufnr)
  end
  self.bufnr = -1
end

---Draw context contents
---@param context table
function View:draw(context)
  -- expand item list
  self._items = {}
  for item in context.root:walk() do
    if self._show_hidden_files or item.name:sub(1, 1) ~= '.' then
      table.insert(self._items, item)
    end
  end
  self:redraw()
end

function View:get_current()
  return self:get_item(vim.fn.line('.'))
end

---@param lnum number
function View:get_item(lnum)
  return self._items[lnum]
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

function View:move_cursor(path)
  local lnum = self:indexof(path)
  -- Skip header line
  core.cursor.move(math.max(lnum, 2))
end

function View:num_lines()
  return #self._items
end

function View:open()
  vim.command('silent buffer ' .. self.bufnr)
end

function View:redraw()
  local winnr = self:winnr()
  if winnr < 0 then
    core.message.warning(
      'Cannot draw because the buffer is not displayed in the window.'
      )
    return
  end

  -- resize window size
  if self._width > 0 then
    vim.command('vertical resize ' .. self._width)
    vim.set_local_option('winfixwidth', true)
  end
  if self._height > 0 then
    vim.command('resize ' .. self._height)
    vim.set_local_option('winfixheight', true)
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
  local lines = {self:_toheader(self._items[1])}
  for i = 2, #self._items do
    table.insert(lines, self:_toline(self._items[i]))
  end

  -- set buffer lines
  local saved_view = vim.fn.winsaveview()

  vim.set_local_option('modifiable', true)
  vim.set_local_option('readonly', false)
  vim.command('silent %delete _')
  vim.fn.setline(1, vim.to_vimlist(lines))
  vim.set_local_option('modifiable', false)
  vim.set_local_option('readonly', true)

  vim.fn.winrestview(saved_view)
end

function View:redraw_line(lnum)
  local item = self:get_item(lnum)
  -- first line is the header line
  local line = lnum == 1 and self:_toheader(item) or self:_toline(item)

  vim.set_local_option('modifiable', true)
  vim.set_local_option('readonly', false)
  vim.fn.setline(lnum, line)
  vim.set_local_option('modifiable', false)
  vim.set_local_option('readonly', true)
end

function View:reset(options)
  self:_reset(options)
  self:_apply_syntaxes()
  vim.set_local_option('buflisted', self._listed)
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
    core.syntax.match_command(header_group, [[\%1l.*]]),
  }
  local highlights = {}

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

function View:_create_buffer()
  -- Save swapfile option
  local swapfile = vim.get_buf_option_boolean('swapfile')
  vim.set_local_option('swapfile', false)
  vim.command('silent edit ' .. self._bufname)
  vim.set_local_option('swapfile', swapfile)

  -- Set buffer local options
  vim.set_local_options {
    bufhidden = 'hide',
    buflisted = self._listed,
    buftype = 'nofile',
    filetype = 'vfiler',
    modifiable = false,
    modified = false,
    readonly = false,
    swapfile = false,
  }

  print(vim.get_win_option(vim.fn.winnr(), 'number'))

  -- Set window local options
  if vim.fn.exists('&colorcolumn') == 1 then
    vim.set_local_option('colorcolumn', '')
  end
  if vim.fn.has('conceal') == 1 then
    if vim.get_win_option_value('conceallevel') < 2 then
      vim.set_local_option('conceallevel', 2)
    end
    vim.set_local_option('concealcursor', 'nvc')
  end

  vim.set_local_options {
    foldcolumn = '0',
    foldenable = false,
    list = false,
    number = false,
    spell = false,
    wrap = false,
  }
  return vim.fn.bufnr()
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

function View:_reset(options)
  local columns = create_columns(options.columns)
  if not columns then
    return nil
  end

  local split = options.split
  self._width = (split == 'vertical') and options.width or 0
  self._height = (split == 'horizontal') and options.height or 0
  self._listed = options.listed
  self._show_hidden_files = options.show_hidden_files
  self._cache = {
    winwidth = 0,
  }
  self._columns = columns
end

---@param item table
function View:_toheader(item)
  return vim.fn.fnamemodify(item.path, ':~')
end

---@param item table
function View:_toline(item)
  local texts = {}
  local cumulative_width = 0
  for i, column in ipairs(self._columns) do
    local prop = self._cache.column_props[i]

    local cwidth = prop.width
    if column.variable then
      cwidth = math.max(cwidth, (prop.cumulative_width - cumulative_width))
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
