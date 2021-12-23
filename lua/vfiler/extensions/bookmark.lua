local cmdline = require('vfiler/cmdline')
local config = require('vfiler/extensions/bookmark/config')
local core = require('vfiler/core')
local vim = require('vfiler/vim')

local Category = require('vfiler/extensions/bookmark/items/category')
local Item = require('vfiler/extensions/bookmark/items/item')

local DIRPATH = core.path.normalize('~/vimfiles/vfiler')
local FILENAME = 'bookmark.json'
local NO_BOOKMARKS_MESSAGE = 'No bookmarks'

local columns = {
  require('vfiler/extensions/bookmark/columns/indent').new(),
  require('vfiler/extensions/bookmark/columns/icon').new(),
  require('vfiler/extensions/bookmark/columns/name').new(),
  require('vfiler/extensions/bookmark/columns/path').new(),
}

local function write_json(json)
  if not core.path.isdirectory(DIRPATH) then
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
    return Category.new('root')
  end
  local file = io.open(path, 'r')
  local json = file:read('a')
  file:close()
  return Category.from_json(json)
end

local function expand_items(root)
  local items = {}
  for _, category in ipairs(root.children) do
    table.insert(items, category)
    if category.opened then
      for _, item in ipairs(category.children) do
        table.insert(items, item)
      end
    end
  end
  return items
end

local function get_line(item, column_widths)
  local texts = {}
  local expected_width = 0
  local text_width = 0
  for i, column in ipairs(columns) do
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
  return table.concat(texts, ' '), text_width + (#columns - 1)
end

local Bookmark = {}

function Bookmark.add(item)
  local root = read_json()

  -- TODO: completion
  local category_name = cmdline.input('Category name?', 'defualt')
  if not category_name or #category_name == 0 then
    return
  end

  local name = cmdline.input('Name?', item.name)
  if not name or #name == 0 then
    return
  end

  local category = root:find_category(category_name)
  if not category then
    category = Category.new(category_name)
    root:add(category)
  end

  local bookmark_item = Item.new(name, item.path)
  category:add(bookmark_item)
  write_json(root:to_json())
end

function Bookmark.new(filer, options)
  -- check configs
  local configs = config.configs
  if configs.options.floating and not core.is_nvim then
    core.message.error('Floating window is not supported by Vim.')
    return nil
  end

  local Extension = require('vfiler/extensions/extension')
  return core.inherit(
    Bookmark, Extension, filer, 'Bookmark', configs, options
  )
end

function Bookmark:save()
  write_json(self._root:to_json())
end

function Bookmark:select(path, open)
  local item = self:get_current()
  self:quit()

  if self.on_selected then
    self._filer:do_action(self.on_selected, path, open)
  end
  return item
end

function Bookmark:_on_initialize_items(configs)
  self._root = read_json()
  return expand_items(self._root)
end

function Bookmark:_on_update_items(configs)
  return expand_items(self._root)
end

function Bookmark:_on_set_buf_options(configs)
  return {
    filetype = 'vfiler_bookmark',
    modifiable = false,
    modified = false,
    readonly = true,
  }
end

function Bookmark:_on_set_win_options(configs)
  return {
    number = false,
  }
end

function Bookmark:_on_start(winid, bufnr, items, configs)
  -- syntaxes and highlights
  local nomessage_group = 'vfilerBookmark_Warning'
  local syntaxes = {
    core.syntax.clear_command({nomessage_group}),
    core.syntax.match_command(
      nomessage_group, [[\%1l]] .. NO_BOOKMARKS_MESSAGE
    ),
  }
  local highlights = {}
  for _, column in pairs(columns) do
    local column_syntaxes = column:syntaxes()
    if column_syntaxes then
      core.list.extend(syntaxes, column_syntaxes)
    end
    local column_highlights = column:highlights()
    if column_highlights then
      core.list.extend(highlights, column_highlights)
    end
  end

  vim.win_executes(winid, syntaxes)
  vim.win_executes(winid, highlights)
  return 2 -- initial lnum
end

function Bookmark:_on_get_lines(items)
  if #items == 0 then
    return {NO_BOOKMARKS_MESSAGE}
  end
  local width = 0
  local lines = {}
  for _, item in ipairs(items) do
    if item.iscategory then
      local category = item
      local column_widths = {}
      for _, column in ipairs(columns) do
        local cwidth = column:get_width(category.children)
        table.insert(column_widths, cwidth)
      end
      local line, text_width = get_line(category, column_widths)
      table.insert(lines, line)
      width = math.max(width, text_width)
      if category.opened then
        for _, bookmark_item in ipairs(category.children) do
          line, text_width = get_line(bookmark_item, column_widths)
          table.insert(lines, line)
          width = math.max(width, text_width)
        end
      end
    end
  end
  return lines, width
end

function Bookmark:_on_draw(view, lines)
  local bufnr = view.bufnr
  vim.set_buf_option(bufnr, 'modifiable', true)
  vim.set_buf_option(bufnr, 'readonly', false)
  view:draw(lines)
  vim.set_buf_option(bufnr, 'modifiable', false)
  vim.set_buf_option(bufnr, 'readonly', true)
end

return Bookmark
