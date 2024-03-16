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

local ItemContainer = {}
ItemContainer.__index = ItemContainer

function ItemContainer.new(options)
  return setmetatable({
    list = {},
    table = {},
    lnum_indexes = {},
    _show_hidden_files = options.show_hidden_files,
    _gitstatus = options.gitstatus,
    _sort_compare = options.sort_compare,
  }, ItemContainer)
end

function ItemContainer:insert(item, lnum_index)
  table.insert(self.list, item)
  table.insert(self.lnum_indexes, lnum_index)
  self.table[item.path] = {
    index = #self.list,
    item = item,
  }
end

function ItemContainer:insert_recursively(item)
  -- Override gitstatus of items
  item.gitstatus = self._gitstatus[item.path]

  local children = item.children
  if not children then
    return
  end

  table.sort(children, self._sort_compare)
  local prev_sibling
  for i, child in ipairs(children) do
    local hidden = child.name:sub(1, 1) == '.'
    if self._show_hidden_files or not hidden then
      local index = LnumIndex.new(child.level, prev_sibling)
      self:insert(child, index)
      prev_sibling = #self.list

      -- recursive
      self:insert_recursively(child)
      if i ~= #children then
        index.next_sibling = prev_sibling + (#self.list - prev_sibling) + 1
      end
    end
  end
end

function ItemContainer:length()
  if not self.list then
    return 0
  end
  return #self.list
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
  local list = {}
  local tbl = {}

  local cnames = vim.list.from(vim.fn.split(columns, ','))
  for _, cname in ipairs(cnames) do
    local object = column.load(cname)
    if object then
      tbl[cname] = object
      table.insert(list, object)
    else
      core.message.warning('"%s" is not a valid column.', cname)
    end
  end
  if #list <= 0 then
    core.message.error('There are invalid columns. (%s)', columns)
    return nil
  end
  return {
    list = list,
    table = tbl,
  }
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
---@param options table
function View.new(options)
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
  self:reset(options)
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
  local options = context.options
  self._items = ItemContainer.new({
    show_hidden_files = options.show_hidden_files,
    gitstatus = context.gitstatus,
    sort_compare = sort.get(options.sort),
  })
  if self._header then
    self._items:insert(context.root, LnumIndex.new(context.root.level))
  end
  self._items:insert_recursively(context.root)
  self:redraw()
end

--- Get the item in the specified line number
---@param lnum number
function View:get_item(lnum)
  if not self._items then
    return nil
  end
  lnum = lnum or vim.fn.line('.', self:winid())
  return self._items.list[lnum]
end

--- Checked to see if it has the specified column.
---@param name string
function View:has_column(name)
  return self._columns.table[name] ~= nil
end

--- Find the item of the item in the view buffer for the specified path
---@param path string
function View:itemof(path)
  local index = self:indexof(path)
  if index == 0 then
    return nil
  end
  return self._items.list[index]
end

--- Find the index of the item in the view buffer for the specified path
---@param path string
function View:indexof(path)
  local item = self._items.table[path]
  if not item then
    return 0
  end
  return item.index
end

--- Find the line of the item in the view buffer for the specified path
---@param path string
function View:lineof(path)
  local index = self:indexof(path)
  if index == 0 then
    return 0
  end
  return index + (self:top_lnum() - 1)
end

--- Get the index of the first sibling item
function View:indexof_first_sibling(lnum)
  local level = self._items.lnum_indexes[lnum].level
  local top_lnum = self:top_lnum()
  for i = lnum - 1, top_lnum, -1 do
    local index = self._items.lnum_indexes[i]
    if index.level == level and not index.prev_sibling then
      return i
    end
  end
  return top_lnum
end

--- Get the index of the last sibling item
function View:indexof_last_sibling(lnum)
  local level = self._items.lnum_indexes[lnum].level
  for i = lnum + 1, self._items:length() do
    local index = self._items.lnum_indexes[i]
    if index.level == level and not index.next_sibling then
      return i
    end
  end
  return self._items:length()
end

--- Get the index of the next sibling item
function View:indexof_next_sibling(lnum)
  local next = self._items.lnum_indexes[lnum].next_sibling
  if next then
    return next
  end
  return lnum
end

--- Get the index of the previous sibiling item
function View:indexof_prev_sibling(lnum)
  local prev = self._items.lnum_indexes[lnum].prev_sibling
  if prev then
    return prev
  end
  return lnum
end

--- Move the cursor to the position of the specified path
function View:move_cursor(path)
  local lnum = self:indexof(path)
  -- Skip header line
  local line = math.max(lnum, self:top_lnum())
  core.cursor.move(line)
  if self._header and line == 2 then
    -- Correspondence to show the header line
    -- when moving to the beginning of the line.
    vim.fn.execute('normal! zb', 'silent')
  end
end

--- Get the number of line in the view buffer
function View:num_lines()
  return self._items:length()
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
  -- NOTE: for debugging.
  --if not buffer or (buffer.number ~= vim.fn.bufnr()) then
  --  core.message.warning(
  --    'Cannot draw because the buffer is different. (%d != %d)',
  --    buffer.number,
  --    vim.fn.bufnr()
  --  )
  --  return
  --end

  local cache = self._cache
  local winid = self:winid()
  if winid < 0 then
    -- NOTE: for debugging.
    --core.message.warning('The buffer is invisible and cannot be drawn.')
    return
  elseif cache.winid ~= winid then
    -- set window options
    cache.winid = winid
    vim.set_win_options(winid, self._winoptions)
    self:_apply_syntaxes()
  end

  -- auto resize window
  if self._auto_resize then
    self:_resize()
  end

  local winwidth = vim.fn.winwidth(winid)
  local view_width = winwidth - 1 -- padding end column
  local number = vim.get_win_flag_option(winid, 'number')
  local relativenumber = vim.get_win_flag_option(winid, 'relativenumber')
  if number or relativenumber then
    view_width = view_width - vim.get_win_option(winid, 'numberwidth')
  end

  if cache.view_width ~= view_width or not cache.column_props then
    cache.column_props = self:_create_column_props(view_width)
    cache.view_width = view_width
    cache.win_width = winwidth
  end

  -- create text lines
  local lines = vim.list({})
  if self._header then
    table.insert(lines, self:_to_header(self._items.list[1]))
  end
  for i = self:top_lnum(), self._items:length() do
    table.insert(lines, self:_to_line(self._items.list[i]))
  end

  -- set buffer lines
  --local saved_view = vim.fn.winsaveview()
  core.try({
    function()
      buffer:set_option('modifiable', true)
      buffer:set_option('readonly', false)
      buffer:set_lines(lines)
    end,
    finally = function()
      buffer:set_option('modifiable', false)
      buffer:set_option('readonly', true)
      --vim.fn.winrestview(saved_view)
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
    line = self:_to_header(item)
  else
    line = self:_to_line(item)
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

--- Reset from another options
---@param options table
function View:reset(options)
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
  for _, item in ipairs(self._items.list) do
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
    for _, item in ipairs(self._items.list) do
      coroutine.yield(item)
    end
  end
  return coroutine.wrap(_walk_items)
end

-- Get the width value
function View:width()
  return self._cache.win_width
end

--- Get the window ID of the view
function View:winid()
  if not self._window then
    return 0
  end
  return self._window:id()
end

function View:_apply_syntaxes()
  local syn_commands = {}
  local hi_commands = {}

  for _, column in pairs(self._columns.table) do
    local syntaxes = column:syntaxes()
    if syntaxes then
      core.list.extend(syn_commands, syntaxes)
    end
    local highlights = column:highlights()
    if highlights then
      core.list.extend(hi_commands, highlights)
    end
  end

  -- Header syntax highlight
  local header_group = 'vfilerHeader'
  table.insert(syn_commands, core.syntax.clear(header_group))
  if self._header then
    table.insert(
      syn_commands,
      core.syntax.create(header_group, {
        match = '\\%1l.\\+',
      }, {
        oneline = true,
        display = true,
      })
    )
  end

  vim.commands(syn_commands)
  vim.commands(hi_commands)
end

function View:_clear_cache()
  self._cache = {
    view_width = 0,
    win_width = 0,
  }
end

function View:_create_column_props(width)
  local winid = self._cache.winid
  local columns = self._columns.list
  local props = {}
  local variable_columns = {}

  -- Subtract the space between columns
  local rest_width = width - (#columns - 1)

  for i, column in ipairs(columns) do
    local cwidth = 0
    if column.variable then
      -- calculate later
      table.insert(variable_columns, { index = i, object = column })
    else
      cwidth = column:get_width(self._items.list, rest_width, winid)
    end
    table.insert(props, { width = cwidth })
    rest_width = rest_width - cwidth
  end

  -- decide variable column width
  if #variable_columns > 0 then
    local width_by_columns = math.floor(rest_width / #variable_columns)
    for _, column in ipairs(variable_columns) do
      props[column.index].width =
        column.object:get_width(self._items.list, width_by_columns, winid)
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

function View:_resize()
  local config = self._win_config
  self._window:resize(config.width, config.height)
end

---@param item table
function View:_to_header(item)
  local width = self._cache.view_width
  local header = core.path.escape(vim.fn.fnamemodify(item.path, ':~'))
  return core.string.truncate(header, width, '<', width)
end

---@param item table
function View:_to_line(item)
  local winid = self._cache.winid
  local col = 0
  local texts = {}
  for i, column in ipairs(self._columns.list) do
    local prop = self._cache.column_props[i]

    local cwidth = prop.width
    if column.variable then
      cwidth = cwidth + (prop.start_col - col)
    end

    local text, width = column:get_text(item, cwidth, winid)
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
    if col > self._cache.view_width then
      break
    end

    table.insert(texts, text)
    col = col + 1 -- "1" is space between columns
  end
  return table.concat(texts, ' ')
end

return View
