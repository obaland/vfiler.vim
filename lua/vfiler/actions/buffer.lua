local utils = require('vfiler/actions/utilities')
local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local VFiler = require('vfiler/vfiler')

local M = {}

------------------------------------------------------------------------------
-- Control buffer
------------------------------------------------------------------------------

local function reload(context, view, reload_all_dir)
  local item = view:get_item()
  if item then
    context:save(item.path)
  end
  context:reload(reload_all_dir)
  view:draw(context)
  view:git_status_async(context.root.path, function(v)
    v:redraw()
  end)
end

function M.quit(vfiler, context, view)
  if context.options.quit then
    utils.close_preview(vfiler, context, view)
    vfiler:quit()
  end
end

function M.quit_force(vfiler, context, view)
  utils.close_preview(vfiler, context, view)
  vfiler:quit()
end

function M.redraw(vfiler, context, view)
  view:redraw()
end

function M.reload(vfiler, context, view)
  reload(context, view, false)
end

function M.reload_all(vfiler, context, view)
  VFiler.foreach(M.reload)
end

function M.reload_all_dir(vfiler, context, view)
  reload(context, view, true)
end

function M.reload_all_dir_all(vfiler, context, view)
  VFiler.foreach(M.reload_all_dir)
end

function M.switch_to_filer(vfiler, context, view)
  -- only window style
  if view:type() ~= 'window' then
    return
  end

  -- close preview window
  utils.close_preview(vfiler, context, view)

  local linked = context.linked
  -- already linked
  if linked then
    if linked:visible() then
      linked:focus()
    else
      linked:open('right')
    end
    linked:do_action(utils.open_preview)
    return
  end

  -- create link to filer
  local lnum = vim.fn.line('.')
  local newfiler = vfiler:copy()
  newfiler:open('right')
  newfiler:link(vfiler)
  newfiler:start(context.root.path)
  core.cursor.move(lnum)

  view:draw(context)
  newfiler:do_action(utils.open_preview)
end

function M.sync_with_current_filer(vfiler, context, view)
  local linked = context.linked
  if not (linked and linked:visible()) then
    return
  end
  linked:update(context)
  linked:do_action(utils.cd, context.root.path)
end

return M
