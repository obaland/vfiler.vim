local core = require('vfiler/libs/core')
local sort = require('vfiler/sort')
local vim = require('vfiler/libs/vim')

local LnumIndex = {}
LnumIndex.__index = LnumIndex

function LnumIndex.new(level, prev_sibling, next_sibling)
  return setmetatable({
    level = level,
    prev_sibling = prev_sibling,
    next_sibling = next_sibling,
  }, LnumIndex)
end

local function new_window(layout)
  local window
  if layout == 'floating' then
    assert(core.is_nvim, 'Vim does not support floating windows.')
    window = require('vfiler/windows/floating')
  else
    window = require('vfiler/windows/window')
  end
  return window.new()
end

local function create_columns(columns)
  local column = require('vfiler/column')
  local objects = {}

  local cnames = vim.list.from(vim.fn.split(columns, ','))
  for _, cname in ipairs(cnames) do
    local object = column.load(cname)
    if object then
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

local function get_window_size(layout, wvalue, hvalue)
  local width, height
  if layout == 'floating' or layout == 'right' or layout == 'left' then
    if core.math.type(wvalue) == 'float' then
      width = math.floor(vim.get_option('columns') * wvalue)
    else
      width = wvalue
    end
  else
    width = 0
  end
  if layout == 'floating' or layout == 'top' or layout == 'bottom' then
    if core.math.type(hvalue) == 'float' then
      height = math.floor(vim.get_option('lines') * hvalue)
    else
      height = hvalue
    end
  else
    height = 0
  end
  return width, height
end

local function to_win_config(options)
  local width, height =
    get_window_size(options.layout, options.width, options.height)
  local col = options.col
  if col == 0 then
    -- Calculate so that the window is in the middle.
    col = math.floor((vim.get_option('columns') - width) / 2) - 1
  end

  local row = options.row
  if row == 0 then
    -- Calculate so that the window is in the middle.
    row = math.floor((vim.get_option('lines') - height) / 2) - 1
  end

  return {
    border = options.border,
    col = col,
    row = row,
    height = height,
    width = width,
    zindex = options.zindex,
    winblend = options.blend,
  }
end

local View = {}
View.__index = View

--- Create a view object
---@param context table
function View.new(context)
  local self = setmetatable({
    _buffer = nil,
    _window = nil,
    _winconfig = {},
    _winoptions = {
      colorcolumn = '',
      concealcursor = 'nvc',
      conceallevel = 2,
      foldcolumn = 0,
      foldenable = false,
      list = false,
      number = false,
      relativenumber = false,
      signcolumn = 'no',
      spell = false,
      wrap = false,
    },
  }, View)
  self:reset(context)
  return self
end

--- Get buffer number
function View:bufnr()
  if not self._buffer then
    return 0
  end
  return self._buffer.number
end

function View:close()
  if self._window and vim.fn.winnr('$') > 1 then
    self._window:close()
  end
end

--- Draw along the context
---@param context table
function View:draw(context)
  -- flatten hierarchical items into a list
  self._items = {}
  self._lnum_indexes = {}
  if self._header then
    table.insert(self._items, context.root)
    table.insert(self._lnum_indexes, LnumIndex.new(context.root.level))
  end

  local options = context.options
  self:_flatten_items(
    context.root,
    sort.get(options.sort),
    context.gitstatus,
    options.show_hidden_files
  )

  self:redraw()
end

--- Get the item in the specified line number
---@param lnum number
function View:get_item(lnum)
  if not self._items then
    return nil
  end
  lnum = lnum or vim.fn.line('.')
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

--- Get the index of the first sibling item
function View:indexof_first_sibling(lnum)
  local level = self._lnum_indexes[lnum].level
  local top_lnum = self:top_lnum()
  for i = lnum - 1, top_lnum, -1 do
    local index = self._lnum_indexes[i]
    if index.level == level and not index.prev_sibling then
      return i
    end
  end
  return top_lnum
end

--- Get the index of the last sibling item
function View:indexof_last_sibling(lnum)
  local level = self._lnum_indexes[lnum].level
  local lines = #self._items
  for i = lnum + 1, #self._lnum_indexes do
    local index = self._lnum_indexes[i]
    if index.level == level and not index.next_sibling then
      return i
    end
  end
  return lines
end

--- Get the index of the next sibling item
function View:indexof_next_sibling(lnum)
  local next = self._lnum_indexes[lnum].next_sibling
  if next then
    return next
  end
  return lnum
end

--- Get the index of the previous sibiling item
function View:indexof_prev_sibling(lnum)
  local prev = self._lnum_indexes[lnum].prev_sibling
  if prev then
    return prev
  end
  return lnum
end

--- Move the cursor to the position of the specified path
function View:move_cursor(path)
  local lnum = self:indexof(path)
  -- Skip header line
  core.cursor.move(math.max(lnum, self:top_lnum()))
  -- Correspondence to show the header line
  -- when moving to the beginning of the line.
  vim.fn.execute('normal zb', 'silent')
end

--- Get the number of line in the view buffer
function View:num_lines()
  if not self._items then
    return 0
  end
  return #self._items
end

--- Open the view buffer for the current window
---@param buffer table
function View:open(buffer, layout)
  layout = layout or 'none'
  self._window = new_window(layout)
  if not (layout == 'none' or layout == 'floating') then
    core.window.open(layout)
  end
  self._window:open(buffer, self._win_config)

  -- set winblend (only floating)
  if self._window:type() == 'floating' then
    self._window:set_option('winblend', self._win_config.winblend)
  end

  self._buffer = buffer
  self:_resize()
  self:_clear_cache()
end

--- Redraw the current contents
function View:redraw()
  local buffer = self._buffer
  if buffer.number ~= vim.fn.bufnr() then
    -- for debug
    --core.message.warning(
    --  'Cannot draw because the buffer is different. (%d != %d)',
    --  buffer.number,
    --  vim.fn.bufnr()
    --)
    return
  end

  local cache = self._cache
  local winid = self:winid()
  if winid < 0 then
    core.message.warning('The buffer is invisible and cannot be drawn.')
    return
  elseif cache.winid ~= winid then
    -- set window options
    vim.set_win_options(winid, self._winoptions)
    self:_apply_syntaxes()
    cache.winid = winid
  end

  -- auto resize window
  if self._auto_resize then
    self:_resize()
  end

  local winwidth = vim.fn.winwidth(winid) - 1 -- padding endline
  local number = vim.get_win_flag_option(winid, 'number')
  local relativenumber = vim.get_win_flag_option(winid, 'relativenumber')
  if number or relativenumber then
    winwidth = winwidth - vim.get_win_option(winid, 'numberwidth')
  end

  if cache.winwidth ~= winwidth or not cache.column_props then
    cache.column_props = self:_create_column_props(winwidth)
    cache.winwidth = winwidth
  end

  -- create text lines
  local lines = vim.list({})
  if self._header then
    table.insert(lines, self:_toheader(self._items[1]))
  end
  for i = self:top_lnum(), #self._items do
    table.insert(lines, self:_toline(self._items[i]))
  end

  -- set buffer lines
  local saved_view = vim.fn.winsaveview()
  core.try({
    function()
      buffer:set_option('modifiable', true)
      buffer:set_option('readonly', false)
      buffer:set_lines(lines)
    end,
    finally = function()
      buffer:set_option('modifiable', false)
      buffer:set_option('readonly', true)
      vim.fn.winrestview(saved_view)
    end,
  })

  -- set title (only floating)
  if self._window:type() == 'floating' then
    self._window:set_title(self._buffer:name())
  end
end

--- Redraw the contents of the specified line number
function View:redraw_line(lnum)
  local item = self:get_item(lnum)
  local line
  if self._header and lnum == 1 then
    line = self:_toheader(item)
  else
    line = self:_toline(item)
  end

  local buffer = self._buffer
  core.try({
    function()
      buffer:set_option('modifiable', true)
      buffer:set_option('readonly', false)
      buffer:set_line(lnum, line)
    end,
    finally = function()
      buffer:set_option('modifiable', false)
      buffer:set_option('readonly', true)
    end,
  })
end

--- Reset from another context
---@param context table
function View:reset(context)
  local options = context.options
  self._columns = create_columns(options.columns)
  if not self._columns then
    return nil
  end

  self._auto_resize = options.auto_resize
  self._header = options.header
  self._win_config = to_win_config(options)
  self:_clear_cache()
end

--- Set size
---@param width number
---@param height number
function View:set_size(width, height)
  self._win_config.width = width
  self._win_config.height = height
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
      selected = { self:get_item(lnum) }
    end
  end
  return selected
end

--- Get the top line number of the visible item
function View:top_lnum()
  return self._header and 2 or 1
end

--- Get the window type
function View:type()
  return self._window:type()
end

--- Walk view items
function View:walk_items()
  if not self._items then
    return nil
  end
  local function _walk_items()
    for _, item in ipairs(self._items) do
      coroutine.yield(item)
    end
  end
  return coroutine.wrap(_walk_items)
end

--- Get the window number of the view
function View:winnr()
  return vim.fn.bufwinnr(self._buffer.number)
end

--- Get the window ID of the view
function View:winid()
  return self._window:id()
end

function View:_apply_syntaxes()
  local header_group = 'vfilerHeader'
  local syntaxes = {
    core.syntax.clear_command({ header_group }),
  }
  local highlights = {}

  if self._header then
    table.insert(
      syntaxes,
      core.syntax.match_command(header_group, [[\%1l.*]])
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

function View:_clear_cache()
  self._cache = { winwidth = 0 }
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
      table.insert(variable_columns, { index = i, object = column })
    else
      width = column:get_width(self._items, rest_width)
    end
    table.insert(props, { width = width })
    rest_width = rest_width - width
  end

  -- decide variable column width
  if #variable_columns > 0 then
    local width_by_columns = math.floor(rest_width / #variable_columns)
    for _, column in ipairs(variable_columns) do
      props[column.index].width =
        column.object:get_width(self._items, width_by_columns)
    end
  end

  local start_col = 0
  for _, prop in ipairs(props) do
    prop.start_col = start_col
    prop.end_col = start_col + prop.width
    start_col = prop.end_col + 1 -- "1" is space between columns
  end
  return props
end

function View:_flatten_items(item, sort_compare, gitstatus, show_hidden_files)
  -- Override gitstatus of items
  item.gitstatus = gitstatus[item.path]

  local children = item.children
  if not children then
    return
  end

  table.sort(children, sort_compare)
  local prev_sibling
  for i, child in ipairs(children) do
    local hidden = child.name:sub(1, 1) == '.'
    if show_hidden_files or not hidden then
      local index = LnumIndex.new(child.level, prev_sibling)

      table.insert(self._items, child)
      table.insert(self._lnum_indexes, index)
      prev_sibling = #self._items

      -- recursive flattening
      self:_flatten_items(child, sort_compare, gitstatus, show_hidden_files)

      if i ~= #children then
        index.next_sibling = prev_sibling + (#self._items - prev_sibling) + 1
      end
    end
  end
end

function View:_resize()
  local config = self._win_config
  self._window:resize(config.width, config.height)
end

---@param item table
function View:_toheader(item)
  local winwidth = self._cache.winwidth
  local header = core.path.escape(vim.fn.fnamemodify(item.path, ':~'))
  return core.string.truncate(header, winwidth, '<', winwidth)
end

---@param item table
function View:_toline(item)
  local col = 0
  local texts = {}
  for i, column in ipairs(self._columns) do
    local prop = self._cache.column_props[i]

    local cwidth = prop.width
    if column.variable then
      cwidth = cwidth + (prop.start_col - col)
    end

    local text, width = column:get_text(item, cwidth)
    col = col + width

    if column.stretch then
      -- Adjust to fit column end base position
      local padding = prop.end_col - col
      if padding > 0 then
        text = text .. (' '):rep(padding)
        col = prop.end_col
      end
    end

    -- If the actual width exceeds the window width,
    -- it will be interrupted
    if col > self._cache.winwidth then
      break
    end

    table.insert(texts, text)
    col = col + 1 -- "1" is space between columns
  end
  return table.concat(texts, ' ')
end

return View
