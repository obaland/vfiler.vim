local config = require 'vfiler/extensions/config'
local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local extension_resources = {}

local Extension = {}
Extension.__index = Extension

function Extension.new(name, view, ...)
  local object = setmetatable({
      configs = core.deepcopy(... or config.configs),
      items = nil,
      name = name,
      bufnr = 0,
      winid = 0,
      view = view,
    }, Extension)
  return object
end

function Extension.create_view(layout, mapping_type)
  local view = nil
  if layout.floating then
    if vim.fn.has('nvim') == 1 then
      view = require('vfiler/extensions/views/floating').new(
        layout, mapping_type
       )
    else
      view = require('vfiler/extensions/views/popup').new(
        layout, mapping_type
        )
    end
  else
    view = require('vfiler/extensions/views/window').new(
      layout, mapping_type
      )
  end
  return view
end

-- @param bufnr number
function Extension.get(bufnr)
  return extension_resources[bufnr]
end

-- @param bufnr number
function Extension.destroy(bufnr)
  local ext = extension_resources[bufnr]
  if ext then
    ext:delete()
  end
  extension_resources[bufnr] = nil
end

function Extension:delete()
  self.view:delete()
  if self.on_delete then
    self.on_delete()
  end
end

function Extension:quit()
  self.view:close()
end

function Extension:start(items, cursor_pos)
  local texts = self:_on_get_texts(items)

  self.winid = self.view:open(self.name, texts)
  self.bufnr = vim.fn.winbufnr(self.winid)
  self.items = items

  -- draw line texts and syntax
  self:_on_draw(texts)
  vim.fn.cursor(cursor_pos, 1)

  -- autocmd
  local delete_func = (
    [[require('vfiler/extensions/extension').destroy(%s)]]
    ):format(self.bufnr)
  local aucommands = {
    [[augroup vfiler_extension]],
    [[  autocmd BufWinLeave <buffer> :lua ]] .. delete_func,
    [[augroup END]],
  }
  for _, au in ipairs(aucommands) do
    vim.command(au)
  end

  -- add extension table
  extension_resources[self.bufnr] = self
end

function Extension:_on_get_texts(items)
  return nil
end

function Extension:_on_draw(texts)
end

return Extension
