local api = require('vfiler/actions/api')
local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local M = {}

------------------------------------------------------------------------------
-- Control buffer
------------------------------------------------------------------------------

function M.quit(vfiler, context, view)
  api.close_preview(vfiler, context, view)
  vfiler:quit()
end

function M.quit_force(vfiler, context, view)
  api.close_preview(vfiler, context, view)
  vfiler:quit(true)
end

function M.redraw(vfiler, context, view)
  view:redraw()
end

function M.reload(vfiler, context, view)
  context:save(view:get_item().path)
  context:switch(context.root.path)
  view:draw(context)
end

function M.switch_to_filer(vfiler, context, view)
  -- only window style
  if view:type() ~= 'window' then
    return
  end

  -- close preview window
  api.close_preview(vfiler, context, view)

  local linked = context.linked
  -- already linked
  if linked then
    if linked:visible() then
      linked:focus()
    else
      linked:open('right')
    end
    linked:do_action(api.open_preview)
    return
  end

  -- create link to filer
  local lnum = vim.fn.line('.')
  local newfiler = vfiler:copy()
  newfiler:open('right')
  newfiler:link(vfiler)
  newfiler:start(context.root.path)
  core.cursor.move(lnum)

  -- redraw current
  vfiler:focus()
  view:draw(context)

  newfiler:focus() -- return other filer
  newfiler:do_action(api.open_preview)
end

function M.sync_with_current_filer(vfiler, context, view)
  local linked = context.linked
  if not (linked and linked:visible()) then
    return
  end

  linked:focus()
  linked:update(context)
  linked:do_action(api.cd, context.root.path)
  vfiler:focus() -- return current window
end

return M
