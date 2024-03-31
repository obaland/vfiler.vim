local cmdline = require('vfiler/libs/cmdline')
local config = require('vfiler/extensions/bookmark/config')
local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local Category = require('vfiler/extensions/bookmark/items/category')
local Item = require('vfiler/extensions/bookmark/items/item')

local DIRPATH = core.path.normalize('~/vimfiles/vfiler')
local FILENAME = 'bookmark.json'

local default_columns = {
  indent = require('vfiler/extensions/bookmark/columns/indent').new(),
  icon = require('vfiler/extensions/bookmark/columns/icon').new(),
  name = require('vfiler/extensions/bookmark/columns/name').new(),
  path = require('vfiler/extensions/bookmark/columns/path').new(),
}

local current_category_names = {}

--- Create column objects
---@return table
local function create_columns()
  local columns = {}
  table.insert(columns, default_columns.indent)
  -- NOTE: If `vfiler-columns-devicons` exists, it takes precedence.
  local ok, _ = pcall(require, 'vfiler/columns/devicons')
  if ok then
    local icon = require('vfiler/extensions/bookmark/columns/icon').new({
      file = '',
      directory = '',
      closed = '',
      opened = '',
      unknown = '',
    })
    table.insert(columns, icon)
  else
    table.insert(columns, default_columns.icon)
  end
  table.insert(columns, default_columns.name)
  table.insert(columns, default_columns.path)
  return columns
end

local function write_json(json)
  if not core.path.is_directory(DIRPATH) then
    vim.fn.mkdir(DIRPATH, 'p')
  end
  local path = core.path.join(DIRPATH, FILENAME)
  local file = io.open(path, 'w')
  file:write(json)
  file:close()
end

local function read_json()
  local path = core.path.join(DIRPATH, FILENAME)
  if not core.path.filereadable(path) then
    -- not existing bookmark file
    return Category.new_root()
  end
  local file = io.open(path, 'r')
  if not file then
    core.message.error(('Cannot open bookmark file. (%s)'):format(path))
    return Category.new_root()
  end
  local json = file:read('a')
  file:close()

  local root = Category.from_json(json)
  current_category_names = {}
  for _, category in ipairs(root.children) do
    table.insert(current_category_names, category.name)
  end
  return root
end

local Bookmark = {}

--- Completion function for command definition.
---@param arglead string
---@return table
function Bookmark.complete(arglead)
  local list = {}
  for _, name in ipairs(current_category_names) do
    if name:find(arglead) then
      table.insert(list, name)
    end
  end
  if #list > 1 then
    table.sort(list)
  end
  return list
end

--- Add bookmark process.
---@param item Item
function Bookmark.add(item)
  local root = read_json()
  local completion = 'customlist,vfiler#bookmark#complete'
  local category_name = cmdline.input('Category name?', '', completion)
  if not category_name then
    return
  end

  local name = cmdline.input('Name?', item.name)
  if not name or #name == 0 then
    return
  end

  local category = root
  if #category_name > 0 then
    local find = root:find_category(category_name)
    if find then
      category = find
    else
      category = Category.new(category_name)
      root:add(category)
    end
  end

  if category:find_item(name) then
    if cmdline.util.confirm_overwrite(name) ~= cmdline.choice.YES then
      return
    end
  end

  local bookmark_item = Item.new(name, item.path)
  category:add(bookmark_item)
  write_json(root:to_json())

  if #category_name > 0 then
    core.message.info(
      'Add bookmark - %s/%s (%s)',
      category.name,
      item.name,
      item.path
    )
  else
    core.message.info(
      'Add bookmark - %s (%s)',
      item.name,
      item.path
    )
  end
end

function Bookmark.new(filer, options)
  -- check configs
  local configs = config.configs
  if configs.options.floating and not core.is_nvim then
    core.message.error('Floating window is not supported by Vim.')
    return nil
  end

  local Extension = require('vfiler/extensions/extension')
  local self = core.inherit(
    Bookmark,
    Extension,
    filer,
    'Bookmark',
    configs,
    options
  )
  self._columns = create_columns()
  return self
end

function Bookmark:change_category(item)
  local parent = item.parent
  local category_name = cmdline.input(
    'Category name?',
    parent.name,
    'customlist,vfiler#bookmark#complete'
  )
  if category_name == parent.name then
    return
  end

  if #category_name > 0 then
    local category = self._root:find_category(category_name)
    if not category then
      category = Category.new(category_name)
      self._root:add(category)
    end
    item:delete()
    category:add(item)
  else
    item:delete()
    self._root:add(item)
  end
  self:update()
end

function Bookmark:update()
  local root = Category.new_root()
  for _, item in ipairs(self._root.children) do
    if item.type == 'category' then
      if item.children and #item.children > 0 then
        root:add(item)
      end
    else
      root:add(item)
    end
  end
  self._root = root
end

function Bookmark:save()
  write_json(self._root:to_json())
end

function Bookmark:select(path, open)
  local item = self:get_item()
  self:quit()

  if self.on_selected then
    self._filer:do_action(self.on_selected, path, open)
  end
  return item
end

function Bookmark:_on_initialize(configs)
  self._root = read_json()
  if #self._root.children == 0 then
    core.message.warning('No bookmarks.')
    self:quit()
    return nil
  end
  return self:_on_update(configs)
end

function Bookmark:_on_update(_)
  self._list = {}
  local items = {}
  for _, item in ipairs(self._root.children) do
    table.insert(self._list, item)
    table.insert(items, item)
    if item.children then
      for _, child in ipairs(item.children) do
        table.insert(self._list, child)
        if item.opened then
          table.insert(items, child)
        end
      end
    end
  end
  return items
end

function Bookmark:_on_opened(winid, _, _, _)
  -- syntaxes and highlights
  local syntaxes = {}
  local highlights = {}
  for _, column in pairs(self._columns) do
    local commands = column:syntaxes()
    if commands then
      core.list.extend(syntaxes, commands)
    end
    commands = column:highlights()
    if commands then
      core.list.extend(highlights, commands)
    end
  end

  vim.win_executes(winid, syntaxes, 'silent')
  vim.win_executes(winid, highlights, 'silent')
  return 2 -- initial lnum
end

function Bookmark:_get_line(item, column_widths)
  local texts = {}
  local expected_width = 0
  local text_width = 0
  for i, column in ipairs(self._columns) do
    local text, width = column:get_text(item)
    text_width = text_width + width
    expected_width = expected_width + column_widths[i]
    if column.stretch then
      local diff = expected_width - text_width
      if diff > 0 then
        text = text .. (' '):rep(diff)
        text_width = text_width + diff
      end
    end
    table.insert(texts, text)
  end
  -- margin at the right edge (+1)
  return table.concat(texts, ' '), text_width + (#self._columns - 1) + 1
end

function Bookmark:_get_lines(items)
  -- Calculate the width of each column.
  local column_widths = {}
  for _, column in ipairs(self._columns) do
    local cwidth = column:get_width(self._list)
    table.insert(column_widths, cwidth)
  end

  local width = 0
  local lines = vim.list({})
  for _, item in ipairs(items) do
    local line, text_width = self:_get_line(item, column_widths)
    table.insert(lines, line)
    width = math.max(width, text_width)
  end
  return lines, width
end

return Bookmark
