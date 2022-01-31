local config = require('vfiler/extensions/menu/config')
local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local Menu = {}

function Menu.new(filer, name, options)
  local Extension = require('vfiler/extensions/extension')
  return core.inherit(Menu, Extension, filer, name, config.configs, options)
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

function Menu:_on_get_lines(items)
  local width = 0
  local lines = vim.list({})
  for _, item in ipairs(items) do
    -- add padding
    local line = ' ' .. item
    width = math.max(width, vim.fn.strwidth(line))
    table.insert(lines, line)
  end
  return lines, width
end

function Menu:_on_opened(winid, buffer, items, configs)
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
