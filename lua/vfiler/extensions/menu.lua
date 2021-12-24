local config = require('vfiler/extensions/menu/config')
local core = require('vfiler/core')
local vim = require('vfiler/vim')

local Menu = {}

function Menu.new(filer, name, options)
  local Extension = require('vfiler/extensions/extension')
  return core.inherit(
    Menu, Extension, filer, name, config.configs, options
  )
end

function Menu:select()
  local item = self:get_current()
  self:quit()

  if self.on_selected then
    self._filer:do_action(self.on_selected, item)
  end
  return item
end

function Menu:_on_initialize(configs)
  return self.initial_items
end

function Menu:_on_buf_options(configs)
  return {
    filetype = 'vfiler_menu',
    modifiable = false,
    modified = false,
    readonly = true,
  }
end

function Menu:_on_win_options(configs)
  return {
    number = false,
  }
end

function Menu:_on_get_lines(items)
  local width = 0
  local lines = {}
  for _, item in ipairs(items) do
    -- add padding
    local line = ' ' .. item
    width = math.max(width, vim.fn.strwidth(line))
    table.insert(lines, line)
  end
  return lines, width
end

function Menu:_on_draw(view, lines)
  local bufnr = view.bufnr
  vim.set_buf_option(bufnr, 'modifiable', true)
  vim.set_buf_option(bufnr, 'readonly', false)
  view:draw(lines)
  vim.set_buf_option(bufnr, 'modifiable', false)
  vim.set_buf_option(bufnr, 'readonly', true)
end

function Menu:_on_opened(winid, bufnr, items, configs)
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
