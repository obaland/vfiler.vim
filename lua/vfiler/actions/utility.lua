local api = require('vfiler/actions/api')
local cmdline = require('vfiler/libs/cmdline')
local core = require('vfiler/libs/core')
local sort = require('vfiler/sort')
local vim = require('vfiler/libs/vim')

local Clipboard = require('vfiler/clipboard')
local Menu = require('vfiler/extensions/menu')

local M = {}

function M.change_sort(vfiler, context, view)
  local menu = Menu.new(vfiler, 'Select Sort', {
    initial_items = sort.types(),
    default = context.options.sort,

    on_selected = function(filer, c, v, sort_type)
      if c.options.sort == sort_type then
        return
      end

      local item = v:get_current()
      c.options.sort = sort_type
      v:draw(c)
      v:move_cursor(item.path)
    end,
  })
  api.start_extension(vfiler, context, view, menu)
end

function M.change_to_parent(vfiler, context, view)
  local current_path = context.root.path
  api.cd(vfiler, context, view, context:parent_path(), function()
    view:move_cursor(current_path)
  end)
end

function M.jump_to_directory(vfiler, context, view)
  local dirpath = cmdline.input('Jump to?', '', 'dir')
  if #dirpath == 0 then
    return
  end
  dirpath = core.path.normalize(dirpath)
  if not core.path.is_directory(dirpath) then
    core.message.error('Not exists the "%s" path.', dirpath)
    return
  end
  api.cd(vfiler, context, view, dirpath)
end

function M.jump_to_home(vfiler, context, view)
  local dirpath = vim.fn.expand('~')
  api.cd(vfiler, context, view, dirpath)
end

function M.jump_to_root(vfiler, context, view)
  local dirpath = core.path.root(context.root.path)
  api.cd(vfiler, context, view, dirpath)
end

function M.sync_with_current_filer(vfiler, context, view)
  local linked = context.linked
  if not (linked and linked:displayed()) then
    return
  end

  linked:focus()
  linked:sync(context, function()
    linked:draw()
    vfiler:focus() -- return current window
  end)
end

function M.toggle_sort(vfiler, context, view)
  local sort_type = context.options.sort
  if sort_type:match('^%l') ~= nil then
    context.options.sort = sort_type:sub(1, 1):upper() .. sort_type:sub(2)
  else
    context.options.sort = sort_type:sub(1, 1):lower() .. sort_type:sub(2)
  end
  view:draw(context)
end

function M.yank_name(vfiler, context, view)
  local selected = view:selected_items()
  local names = {}
  for _, item in ipairs(selected) do
    table.insert(names, item.name)
  end
  if #names == 1 then
    Clipboard.yank(names[1])
    core.message.info('Yanked name - "%s"', names[1])
  elseif #names > 1 then
    local content = table.concat(names, '\n')
    Clipboard.yank(content)
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
    Clipboard.yank(paths[1])
    core.message.info('Yanked path - "%s"', paths[1])
  elseif #paths > 1 then
    local content = table.concat(paths, '\n')
    Clipboard.yank(content)
    core.message.info('Yanked %d paths', #paths)
  end

  -- clear selected mark
  for _, item in ipairs(selected) do
    item.selected = false
  end
  view:redraw()
end

return M
