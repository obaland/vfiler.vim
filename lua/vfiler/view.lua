local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local View = {}
View.__index = View

local function create_columns(columns)
  local column = require 'vfiler/column'
  local objects = {}

  local cnames = vim.from_vimlist(vim.fn.split(columns, ','))
  for _, cname in ipairs(cnames) do
    local object = column.get(cname)
    if column then
      table.insert(objects, object)
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

--- Create a view object
---@param bufname string
---@param options table
function View.new(bufname, options)
  local object = setmetatable({
    bufnr = -1,
    _bufname = bufname,
    _winoptions = {
      colorcolumn = '',
      concealcursor = 'nvc',
      conceallevel = 2,
      foldcolumn = 0,
      foldenable = false,
      list = false,
      number = false,
      relativenumber = false,
      spell = false,
      wrap = false,
    },
  }, View)
  object:_reset(options)
  return object
end

--- Create data that includes a buffer
function View:create()
  self.bufnr = self:_create_buffer()
  self:_apply_syntaxes()
  self:_resize(vim.fn.bufwinnr(self.bufnr))
  return self.bufnr
end

--- Delete view object
function View:delete()
  if self.bufnr >= 0 then
    vim.command('silent bwipeout ' .. self.bufnr)
  end
  self.bufnr = -1
end

--- Draw along the context
---@param context table
function View:draw(context)
  -- expand item list
  self._items = {}
  for item in context.root:walk() do
    if self.show_hidden_files or item.name:sub(1, 1) ~= '.' then
      table.insert(self._items, item)
    end
  end

  -- remove header line
  if not self._header then
    table.remove(self._items, 1)
  end
  self:redraw()
end

--- Get the item on the current cursor
function View:get_current()
  return self:get_item(vim.fn.line('.'))
end

--- Get the item in the specified line number
---@param lnum number
function View:get_item(lnum)
  return self._items[lnum]
end

--- Find the index of the item in the view buffer for the specified path
---@param path string
function View:indexof(path)
  for i, item in ipairs(self._items) do
    if item.path == path then
      return i
    end
  end
  return 0
end

--- Move the cursor to the position of the specified path
function View:move_cursor(path)
  local lnum = self:indexof(path)
  -- Skip header line
  core.cursor.move(math.max(lnum, self:top_lnum()))
end

--- Get the number of line in the view buffer
function View:num_lines()
  return #self._items
end

--- Open the view buffer for the current window
function View:open()
  vim.command('silent buffer ' .. self.bufnr)
end

--- Redraw the current contents
function View:redraw()
  if self.bufnr ~= vim.fn.bufnr() then
    core.message.warning('Cannot draw because the buffer is different.')
    return
  end

  local winnr = self:winnr()
  if winnr < 0 then
    core.message.warning(
      'Cannot draw because the buffer is not displayed in the window.'
      )
    return
  end

  -- set window options
  vim.set_win_options(winnr, self._winoptions)

  local winwidth = vim.fn.winwidth(winnr) - 1 -- padding end
  local cache = self._cache
  if cache.winwidth ~= winwidth or (not cache.column_props) then
    cache.column_props = self:_create_column_props(winwidth)
    cache.winwidth = winwidth
  end

  -- create text lines
  local lines = {}
  if self._header then
    table.insert(lines, self:_toheader(self._items[1]))
  end
  for i = self:top_lnum(), #self._items do
    table.insert(lines, self:_toline(self._items[i]))
  end

  -- set buffer lines
  local saved_view = vim.fn.winsaveview()

  vim.set_buf_option(self.bufnr, 'modifiable', true)
  vim.set_buf_option(self.bufnr, 'readonly', false)
  vim.command('silent %delete _')
  vim.fn.setbufline(self.bufnr, 1, vim.to_vimlist(lines))
  vim.set_buf_option(self.bufnr, 'modifiable', false)
  vim.set_buf_option(self.bufnr, 'readonly', true)

  vim.fn.winrestview(saved_view)
end

--- Redraw the contents of the specified line number
function View:redraw_line(lnum)
  local item = self:get_item(lnum)
  local line = ''
  if self._header and lnum == 1 then
    line = self:_toheader(item)
  else
    line = self:_toline(item)
  end

  vim.set_buf_option(self.bufnr, 'modifiable', true)
  vim.set_buf_option(self.bufnr, 'readonly', false)
  vim.fn.setbufline(self.bufnr, lnum, line)
  vim.set_buf_option(self.bufnr, 'modifiable', false)
  vim.set_buf_option(self.bufnr, 'readonly', true)
end

--- Reset the view object
---@param options table
function View:reset(options)
  self:_reset(options)
  vim.set_buf_option(self.bufnr, 'buflisted', self._listed)
  self:_apply_syntaxes()
  self:_resize(vim.fn.bufwinnr(self.bufnr))
end

--- Get the currently selected items
function View:selected_items()
  local selected = {}
  for _, item in ipairs(self._items) do
    if item.selected then
      table.insert(selected, item)
    end
  end
  if #selected == 0 then
    local lnum = vim.fn.line('.')
    if lnum >= self:top_lnum() then
      selected = {self:get_item(lnum)}
    end
  end
  return selected
end

--- Get the top line number where the item is displayed
function View:top_lnum()
  return self._header and 2 or 1
end

--- Get the window number of the view
function View:winnr()
  return vim.fn.bufwinnr(self.bufnr)
end

function View:_apply_syntaxes()
  local header_group = 'vfilerHeader'
  local syntaxes = {
    core.syntax.clear_command({header_group})
  }
  local highlights = {}

  if self._header then
    table.insert(
      syntaxes, core.syntax.match_command(header_group, [[\%1l.*]])
      )
  end

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
  vim.command('silent edit ' .. self._bufname)

  -- Set buffer local options
  local bufnr = vim.fn.bufnr()
  vim.set_buf_options(bufnr, {
    bufhidden = 'hide',
    buflisted = self._listed,
    buftype = 'nofile',
    filetype = 'vfiler',
    modifiable = false,
    modified = false,
    readonly = false,
    swapfile = false,
  })
  return bufnr
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
  self._columns = create_columns(options.columns)
  if not self._columns then
    return nil
  end

  self.show_hidden_files = options.show_hidden_files
  self._header = options.header
  self._listed = options.listed
  self._cache = {
    winwidth = 0,
  }

  self._width = 0
  self._height = 0

  local direction = options.direction
  if direction == 'left' or direction == 'right' then
    self._width = options.width
  elseif direction == 'top' or direction == 'bottom' then
    self._height = options.height
  end
end

function View:_resize(winnr)
  local winfixwidth = false
  if self._width > 0 then
    core.window.resize_width(self._width)
    winfixwidth = true
  end
  vim.set_win_option(winnr, 'winfixwidth', winfixwidth)

  local winfixheight = false
  if self._height > 0 then
    core.window.resize_height(self._height)
    winfixheight = true
  end
  vim.set_win_option(winnr, 'winfixheight', winfixheight)
end

---@param item table
function View:_toheader(item)
  local winwidth = self._cache.winwidth
  local header = vim.fn.fnamemodify(item.path, ':~')
  return core.string.truncate(header, winwidth, '<', winwidth)
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
      cumulative_width = cumulative_width + padding
    end

    -- If the actual width exceeds the window width,
    -- it will be interrupted
    local actual_width = cumulative_width + (i - 1) -- space between columns
    if actual_width > self._cache.winwidth then
      break
    end

    table.insert(texts, text)
  end
  return table.concat(texts, ' ')
end

return View
