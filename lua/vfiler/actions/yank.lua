local clipboard = require('vfiler/clipboard')
local core = require('vfiler/libs/core')

local M = {}

function M.yank_name(vfiler, context, view)
  local selected = view:selected_items()
  local names = {}
  for _, item in ipairs(selected) do
    table.insert(names, item.name)
  end
  if #names == 1 then
    clipboard.yank(names[1])
    core.message.info('Yanked name - "%s"', names[1])
  elseif #names > 1 then
    local content = table.concat(names, '\n')
    clipboard.yank(content)
    core.message.info('Yanked %d names', #names)
  end

  -- clear selected mark
  for _, item in ipairs(selected) do
    item.selected = false
  end
  view:redraw()
end

function M.yank_path(vfiler, context, view)
  local selected = view:selected_items()
  local paths = {}
  for _, item in ipairs(selected) do
    table.insert(paths, item.path)
  end
  if #paths == 1 then
    clipboard.yank(paths[1])
    core.message.info('Yanked path - "%s"', paths[1])
  elseif #paths > 1 then
    local content = table.concat(paths, '\n')
    clipboard.yank(content)
    core.message.info('Yanked %d paths', #paths)
  end

  -- clear selected mark
  for _, item in ipairs(selected) do
    item.selected = false
  end
  view:redraw()
end

return M
