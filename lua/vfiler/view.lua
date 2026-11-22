local core = require('vfiler/libs/core')
local sort = require('vfiler/sort')
local vim = require('vfiler/libs/vim')

local View = {}
View.__index = View

local function new_lnum_index(level, prev_sibling)
  return {
    level = level,
    prev_sibling = prev_sibling,
  }
end

local ItemContainer = {}
ItemContainer.__index = ItemContainer

function ItemContainer.new(options)
  return setmetatable({
    list = {},
    path_indexes = {},
    lnum_indexes = {},
    _show_hidden_files = options.show_hidden_files,
    _sort_compare = options.sort_compare,
  }, ItemContainer)
end

function ItemContainer:insert(item, lnum_index)
  local index = #self.list + 1
  self.list[index] = item
  self.lnum_indexes[index] = lnum_index
  self.path_indexes[item.path] = index
  return index
end

function ItemContainer:insert_recursively(children, git)
  if not children then
    return
  end

  sort.apply(children, self._sort_compare)
  local prev_sibling
  for i, child in ipairs(children) do
    local hidden = child.name:sub(1, 1) == '.'
    if self._show_hidden_files or not hidden then
      local index = new_lnum_index(child.level, prev_sibling)
      prev_sibling = self:insert(child, index)

      child.gitstatus = git and git:status(child.path)
      local descendants = child.children
      if descendants then
        self:insert_recursively(descendants, git)
      end
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

function ItemContainer:update_git(git)
  local has_status = git:has_status()
  for _, item in ipairs(self.list) do
    item.gitstatus = has_status and git:status(item.path) or nil
  end
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

--- Since vim changes the view width depending on the options,
--- check the options that affect the view width to obtain
--- the appropriate view width.
---@param winid number
---@param winwidth number
---@return number
local function get_view_width(winid, winwidth)
  local view_width = winwidth

  local number = vim.get_win_flag_option(winid, 'number')
  local relativenumber = vim.get_win_flag_option(winid, 'relativenumber')
  if number or relativenumber then
    view_width = view_width - vim.get_win_option(winid, 'numberwidth')
  end

  local signcolumn = vim.get_win_option(winid, 'signcolumn')
  if
    signcolumn == 'yes'
    or (signcolumn == 'auto' and #vim.fn.sign_getplaced() > 0)
  then
    view_width = view_width - 2
  end

  -- padding end column
  return view_width - 1
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

local function can_redraw_lines(columns, items, lnums, drawn_at)
  if not drawn_at or #lnums == 0 or #lnums > 32 or #lnums * 2 >= #items then
    return false
  end
  for _, column in pairs(columns) do
    if not column.needs_redraw or column:needs_redraw(items, drawn_at) then
      return false
    end
  end
  return true
end

--- Create a view object
---@param options table
function View.new(options)
  local self = setmetatable({
    _buffer = nil,
    _git = require('vfiler/git').new(options.git),
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
      spell = false,
      wrap = false,
      -- NOTE: Do not explicitly set `signcolumn` in vim, as it will redraw.
      --signcolumn = 'no',
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

function View:clear_selection()
  local lnums = {}
  local top_lnum = self:top_lnum()
  for lnum, item in ipairs(self._items.list) do
    if item.selected then
      item.selected = false
      if lnum >= top_lnum then
        table.insert(lnums, lnum)
      end
    end
  end
  self:redraw(lnums)
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
  local root = context.root
  self._items = ItemContainer.new({
    show_hidden_files = options.show_hidden_files,
    sort_compare = sort.get(options.sort),
  })
  if self._header then
    self._items:insert(root, new_lnum_index(root.level))
  end
  local git
  if self:has_column('git') and self._git:has_status() then
    git = self._git
  end
  root.gitstatus = git and git:status(root.path)
  self._items:insert_recursively(root.children, git)
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
  return self._items.path_indexes[path] or 0
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
  local current = self._items.lnum_indexes[lnum]
  if not current then
    return lnum
  end
  local level = current.level

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
  local current = self._items.lnum_indexes[lnum]
  if not current then
    return lnum
  end
  local level = current.level

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
  local current = self._items.lnum_indexes[lnum]
  local next = current and current.next_sibling
  if next then
    return next
  end
  return lnum
end

--- Get the index of the previous sibiling item
function View:indexof_prev_sibling(lnum)
  local current = self._items.lnum_indexes[lnum]
  local prev = current and current.prev_sibling
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
function View:redraw(lnums)
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

  if not vim.win_is_valid(winid) then
    return
  elseif cache.winid ~= winid then
    lnums = nil
    -- set window options
    cache.winid = winid
    vim.set_win_options(winid, self._winoptions)
    self:_apply_syntaxes()
  end

  -- auto resize window
  if self._auto_resize then
    lnums = nil
    self:_resize()
  end

  local winwidth = vim.fn.winwidth(winid)
  local view_width = get_view_width(winid, winwidth)
  if cache.view_width ~= view_width or not cache.column_props then
    lnums = nil
    cache.column_props = self:_create_column_props(view_width)
    cache.view_width = view_width
    cache.win_width = winwidth
  end

  local items = self._items.list
  local conceallevel = vim.get_win_option(winid, 'conceallevel')
  local columns = self._columns.table
  if lnums then
    if
      cache.conceallevel ~= conceallevel
      or not can_redraw_lines(columns, items, lnums, cache.drawn_at)
    then
      lnums = nil
    end
  end

  -- create text lines
  local lines = {}
  local texts = {}
  local first_lnum = lnums and lnums[1]
  if lnums then
    for i, lnum in ipairs(lnums) do
      if first_lnum and lnum ~= first_lnum + i - 1 then
        first_lnum = nil
      end
      lines[i] = self:_to_line(items[lnum], conceallevel, texts)
    end
  else
    cache.drawn_at = os.time()
    cache.conceallevel = conceallevel
    if self._header then
      table.insert(lines, self:_to_header(items[1]))
    end
    for i = self:top_lnum(), #items do
      table.insert(lines, self:_to_line(items[i], conceallevel, texts))
    end
  end

  -- set buffer lines
  --local saved_view = vim.fn.winsaveview()
  core.try({
    function()
      buffer:set_option('modifiable', true)
      buffer:set_option('readonly', false)
      if first_lnum and #lines > 1 then
        buffer:set_lines(vim.list(lines), first_lnum)
      elseif lnums then
        for i, lnum in ipairs(lnums) do
          buffer:set_line(lnum, lines[i])
        end
      else
        buffer:set_lines(vim.list(lines))
      end
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
  assert(item)
  local line
  if self._header and lnum == 1 then
    line = self:_to_header(item)
  else
    local conceallevel = vim.get_win_option(self:winid(), 'conceallevel')
    line = self:_to_line(item, conceallevel)
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
  self._git:reset(options.git)
  self._header = options.header
  self._win_config = to_win_config(options)
  self:_clear_cache()
end

--- Reloads asynchronously the status of each file under the git repository
--  containing the specified directory path.
--- NOTE: If no git column is set, do nothing.
---@param dirpath string
---@param callback function
function View:git_status_async(dirpath, callback)
  if not self:has_column('git') then
    return
  end
  self._git:status_async(dirpath, function(git, root, status)
    self._items:update_git(git)
    callback(self, root, status)
  end)
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
---@return string: window type string literal
--- 'window': Normal window
--- 'floating': Float window
--- 'popup': Popup window
--- 'none': No window
function View:type()
  if self._window then
    return self._window:type()
  end
  return 'none'
end

--- Walk view items
function View:walk_items()
  if not self._items then
    return nil
  end
  local items
  local index = 0
  return function()
    if not items then
      assert(index == 0, 'item iterator is exhausted')
      items = self._items.list
    end
    index = index + 1
    local item = items[index]
    if item == nil then
      items = nil
    end
    return item
  end
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
---@param conceallevel number
---@param texts? table
function View:_to_line(item, conceallevel, texts)
  local winid = self._cache.winid
  local col = 0
  local count = 0
  texts = texts or {}
  for i, column in ipairs(self._columns.list) do
    local prop = self._cache.column_props[i]

    local cwidth = prop.width
    if column.variable then
      cwidth = cwidth + (prop.start_col - col)
    end

    local text, width = column:get_text(item, cwidth, winid, conceallevel)
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

    if text ~= nil then
      count = count + 1
      texts[count] = text
    end
    col = col + 1 -- "1" is space between columns
  end
  return table.concat(texts, ' ', 1, count)
end

return View
