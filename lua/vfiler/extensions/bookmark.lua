local config = require('vfiler/extensions/bookmark/config')
local core = require('vfiler/core')
local vim = require('vfiler/vim')

local Bookmark = {}

function Bookmark.new(options)
  local Extension = require('vfiler/extensions/extension')
  local view = Extension.create_view({top = 'auto'})

  view:set_buf_options {
    filetype = 'vfiler_bookmark',
    modifiable = false,
    modified = false,
    readonly = true,
  }
  view:set_win_options {
    number = false,
  }

  local configs = config.configs
  local self = core.inherit(
    Bookmark, Extension, options.filer, options.name, view, configs
  )
  self.on_quit = options.on_quit
  self.on_selected = options.on_selected
  return self
end

function Bookmark:_on_get_texts(items)
  return ''
end

function Bookmark:_on_draw(texts)
  local bufnr = self.view.bufnr
  vim.set_buf_option(bufnr, 'modifiable', true)
  vim.set_buf_option(bufnr, 'readonly', false)
  self.view:draw(self.name, texts)
  vim.set_buf_option(bufnr, 'modifiable', false)
  vim.set_buf_option(bufnr, 'readonly', true)
end

return Bookmark
