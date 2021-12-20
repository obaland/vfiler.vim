local config = require('vfiler/extensions/menu/config')
local core = require('vfiler/core')
local vim = require('vfiler/vim')

local Menu = {}

function Menu.new(filer, name, options)
  local Extension = require('vfiler/extensions/extension')

  local configs = config.configs
  local view = Extension.create_view(configs.options)
  view:set_buf_options {
    filetype = 'vfiler_menu',
    modifiable = false,
    modified = false,
    readonly = true,
  }
  view:set_win_options {
    number = false,
  }

  return core.inherit(
    Menu, Extension, filer, name, view, configs, options
  )
end

function Menu:select()
  local item = self:get_current()
  self:quit()

  if self.on_selected then
    local filer = self._filer
    self.on_selected(filer, filer._context, filer._view, item)
  end
  return item
end

function Menu:_on_create_items(configs)
  return self.initial_items
end

function Menu:_on_get_texts(items)
  -- Add padding
  local texts = {}
  for _, item in ipairs(items) do
    table.insert(texts, ' ' .. item)
  end
  return texts
end

function Menu:_on_draw(view, texts)
  local bufnr = view.bufnr
  vim.set_buf_option(bufnr, 'modifiable', true)
  vim.set_buf_option(bufnr, 'readonly', false)
  view:draw(self.name, texts)
  vim.set_buf_option(bufnr, 'modifiable', false)
  vim.set_buf_option(bufnr, 'readonly', true)
end

function Menu:_on_start(winid, bufnr, items, configs)
  if not self.default then
    return 1
  end
  for i = 1, #items do
    if items[i] == self.default then
      return i
    end
  end
  return 1
end

return Menu
