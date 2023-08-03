local utils = require('vfiler/actions/utilities')

local M = {}

function M.open(vfiler, context, view)
  local path = view:get_item().path
  utils.open_file(vfiler, context, view, path)
end

function M.open_by_choose(vfiler, context, view)
  local path = view:get_item().path
  utils.open_file(vfiler, context, view, path, 'choose')
end

function M.open_by_choose_or_cd(vfiler, context, view)
  local item = view:get_item()
  if item.type == 'directory' then
    utils.cd(vfiler, context, view, item.path)
  else
    utils.open_file(vfiler, context, view, item.path, 'choose')
  end
end

function M.open_by_split(vfiler, context, view)
  local path = view:get_item().path
  utils.open_file(vfiler, context, view, path, 'bottom')
end

function M.open_by_tabpage(vfiler, context, view)
  local path = view:get_item().path
  utils.open_file(vfiler, context, view, path, 'tab')
end

function M.open_by_vsplit(vfiler, context, view)
  local path = view:get_item().path
  utils.open_file(vfiler, context, view, path, 'right')
end

return M
