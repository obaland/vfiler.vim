local cmdline = require('vfiler/cmdline')
local config = require('vfiler/extensions/bookmark/config')
local core = require('vfiler/core')
local vim = require('vfiler/vim')

local Category = require('vfiler/extensions/bookmark/items/category')
local Item = require('vfiler/extensions/bookmark/items/item')

local DIRPATH = core.path.normalize('~/vimfiles/vfiler')
local FILENAME = 'bookmark.json'
local NO_BOOKMARKS_MESSAGE = 'No bookmarks'

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
    return nil
  end
end

local Bookmark = {}

function Bookmark.add(item)
  local json = read_json()
  local root = nil
  if json then
  else
    root = Category.new('root')
  end

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

  local bookmark_item = Item.new(name, item)
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
  local view = Extension.create_view(configs.options)

  view:set_buf_options {
    filetype = 'vfiler_bookmark',
    modifiable = false,
    modified = false,
    readonly = true,
  }
  view:set_win_options {
    number = false,
  }

  return core.inherit(
    Bookmark, Extension, filer, 'Bookmark', view, config.configs, options
  )
end

function Bookmark:_on_create_items(configs)
  return {}
end

function Bookmark:_on_start(winid, bufnr, items, configs)
  -- syntaxes and highlights
  local nomessage_group = 'vfilerBookmark_NoMessage'
  local syntaxes = {
    core.syntax.clear_command({nomessage_group}),
    core.syntax.match_command(
      nomessage_group, [[\%1l]] .. NO_BOOKMARKS_MESSAGE
    ),
  }
  for _, syntax in ipairs(syntaxes) do
    vim.fn.win_execute(winid, syntax)
  end

  -- Not implemented
  return 1
end

function Bookmark:_on_get_texts(items)
  if #items == 0 then
    return {NO_BOOKMARKS_MESSAGE}
  end
  return {}
end

function Bookmark:_on_draw(view, texts)
  local bufnr = view.bufnr
  vim.set_buf_option(bufnr, 'modifiable', true)
  vim.set_buf_option(bufnr, 'readonly', false)
  view:draw(self.name, texts)
  vim.set_buf_option(bufnr, 'modifiable', false)
  vim.set_buf_option(bufnr, 'readonly', true)
end

return Bookmark
