local action = require('vfiler/extensions/action')
local cmdline = require('vfiler/libs/cmdline')
local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local function select(extension, open)
  local item = extension:get_current()
  if item.iscategory or not core.path.exists(item.path) then
    return
  end
  extension:select(item.path, open)
end

function action.delete(extension)
  local item = extension:get_current()
  local prompt = 'Are you sure you want to delete? - ' .. item.name
  local choices = { cmdline.choice.YES, cmdline.choice.NO }
  if cmdline.confirm(prompt, choices, 2) ~= cmdline.choice.YES then
    return
  end

  item:delete()
  extension:save()
  core.message.info('Deleted - %s', item.name)
  extension:redraw()
end

function action.rename(extension)
  local item = extension:get_current()
  local name = item.name
  local rename = cmdline.input('New file name - ' .. name, name)

  item.name = rename
  extension:save()
  core.message.info('Renamed - "%s" -> "%s"', name, rename)
  extension:restart()
end

function action.open(extension)
  local item = extension:get_current()
  if item.iscategory then
    action.open_tree(extension)
  else
    select(extension, 'edit')
  end
end

function action.open_by_split(extension)
  select(extension, 'bottom')
end

function action.open_by_tabpage(extension)
  select(extension, 'tab')
end

function action.open_by_vsplit(extension)
  select(extension, 'right')
end

function action.open_tree(extension)
  local lnum = vim.fn.line('.')
  local item = extension:get_item(lnum)
  if not item.iscategory or item.opened then
    return
  end
  item:open()
  extension:redraw()
  core.cursor.winmove(extension.winid, lnum + 1)
end

function action.close_tree(extension)
  local item = extension:get_current()
  local category
  if item.iscategory then
    category = item
  else
    category = item.parent
  end
  category:close()
  extension:redraw()
  core.cursor.winmove(extension.winid, extension:indexof(category))
end

return action
