local action = require('vfiler/extensions/action')
local cmdline = require('vfiler/libs/cmdline')
local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local function select(extension, layout)
  layout = layout or 'none'
  local item = extension:get_current()
  if item.is_category or not core.path.exists(item.path) then
    return
  end
  extension:select(item.path, layout)
end

function action.change_category(extension)
  local item = extension:get_current()
  if item.is_category then
    return
  end
  extension:change_category(item)
  extension:save()
  core.message.info('The category has changed.')
  extension:reload()
  core.cursor.winmove(extension.winid, extension:indexof(item))
end

function action.delete(extension)
  local item = extension:get_current()
  local prompt = 'Are you sure you want to delete? - ' .. item.name
  local choices = { cmdline.choice.YES, cmdline.choice.NO }
  if cmdline.confirm(prompt, choices, 2) ~= cmdline.choice.YES then
    return
  end

  item:delete()
  extension:update()
  extension:save()
  core.message.info('Deleted - %s', item.name)
  extension:reload()
end

function action.rename(extension)
  local item = extension:get_current()
  local name = item.name
  local rename = cmdline.input('New name? - ' .. name, name)
  if #rename == 0 then
    -- canceled
    return
  end

  item.name = rename
  extension:update()
  extension:save()
  core.message.info('Renamed - "%s" -> "%s"', name, rename)
  extension:reload()
  core.cursor.winmove(extension.winid, extension:indexof(item))
end

function action.open(extension)
  local item = extension:get_current()
  if item.is_category then
    action.open_tree(extension)
  else
    select(extension)
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
  if not item.is_category or item.opened then
    return
  end
  item:open()
  extension:redraw()
  core.cursor.winmove(extension:winid(), lnum + 1)
end

function action.close_tree(extension)
  local item = extension:get_current()
  local category
  if item.is_category then
    category = item
  else
    category = item.parent
  end
  category:close()
  extension:redraw()
  core.cursor.winmove(extension:winid(), extension:indexof(category))
end

return action
