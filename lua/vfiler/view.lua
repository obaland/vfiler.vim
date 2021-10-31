local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local View = {}
View.__index = View

local function create_buffer(bufname, configs)
  -- Save swapfile option
  local swapfile = vim.get_buf_option_boolean('swapfile')
  vim.set_buf_option('swapfile', false)
  vim.command('silent edit ' .. bufname)
  vim.set_buf_option('swapfile', swapfile)

  -- Set buffer local options
  vim.set_buf_options {
    bufhidden = 'hide',
    buflisted = configs.listed,
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

  local foldcolumn = 0
  if vim.fn.has('nvim-0.5.0') == 1 then
    foldcolumn = '0'
  end

  vim.set_win_options {
    foldcolumn = foldcolumn,
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

  for _, cname in ipairs(vim.fn.split(columns, ',')) do
    local column = collection.get(cname)
    if column then
      table.insert(objects, column)
    else
      core.warning(("'%s' is not a valid column."):format(cname))
    end
  end
  if #objects <= 0 then
    core.error(('There are no valid columns. (%s)'):format(columns))
    return nil
  end
  return objects
end

---@param bufname string
---@param configs table
function View.new(bufname, configs)
  local columns = create_columns(configs.columns)
  if not columns then
    return nil
  end

  local bufnr = create_buffer(bufname, configs)
  mapping.define('main')

  local object = setmetatable({
    bufname = bufname,
    bufnr = bufnr,
    show_hidden_files = configs.show_hidden_files,
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
  vim.command('silent bwipeout ' .. self.bufnr)
  self.bufnr = 0
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

---@param target table
function View:indexof(target)
  for i, item in ipairs(self._items) do
    if item.path == target.path then
      return i
    end
  end
  return nil
end

function View:num_lines()
  return #self._items
end

function View:open()
  vim.command('silent buffer ' .. self.bufnr)
end

function View:redraw()
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
  vim.fn.setline(1, vim.vim_list(lines))
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
  return selected
end

function View:_apply_syntaxes()
  local header_group = 'vfilerHeader'
  local syntaxes = {
    core.syntax_clear_command({header_group}),
    core.syntax_match_command(header_group, [[\%1l.*']]),
  }
  local highlights = {
    core.link_highlight_command(header_group, 'Statement'),
  }

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

function View:_create_column_props(winwidth)
  local props = {}
  local variable_columns = {}
  local rest_width = winwidth

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

  -- decide column base position
  local pos = 1
  for _, prop in ipairs(props) do
    prop.start_pos = pos
    if prop.width > 0 then
      prop.end_pos = prop.start_pos + prop.width - 1
      pos = prop.end_pos + 1
    else
      prop.end_pos = prop.start_pos
      pos = prop.end_pos
    end
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
  local line = ''
  local lwidth = 0
  for j, column in ipairs(self._columns) do
    local prop = self._cache.column_props[j]

    local cwidth = prop.width
    if column.variable then
      cwidth = cwidth + (prop.start_pos - lwidth - 1)
    end

    local text, width = column:get_text(item, cwidth)
    line = line .. text
    lwidth = lwidth + width

    if column.stretch then
      -- Adjust to fit column end base position
      local padding = prop.end_pos - lwidth
      if padding > 0 then
        line = line .. (' '):rep(padding)
      end
    end
  end
  return line
end

return View
