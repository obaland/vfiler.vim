local cmdline = require 'vfiler/cmdline'
local core = require 'vfiler/core'
local sort = require 'vfiler/sort'
local vim = require 'vfiler/vim'

local ExtensionMenu = require 'vfiler/extensions/menu'
local ExtensionRename = require 'vfiler/extensions/rename'
local Directory = require 'vfiler/items/directory'
local File = require 'vfiler/items/file'
local VFiler = require 'vfiler/vfiler'

local M = {}

local function detect_drives()
  if not core.is_windows then
    return {}
  end
  local drives = {}
  for byte = ('A'):byte(), ('Z'):byte() do
    local drive = string.char(byte) .. ':/'
    if vim.fn.isdirectory(drive) == 1 then
      table.insert(drives, drive)
    end
  end
  return drives
end

local function input_names(message)
  local content = core.input(message)
  return vim.fn.split(content, [[\s*,\s*]])
end

-- @param lnum number
local function move_cursor(lnum)
  vim.fn.cursor(lnum, 1)
end

------------------------------------------------------------------------------
-- interfaces
------------------------------------------------------------------------------
function M.define(name, func)
  M[name] = func
end

function M.do_action(name, ...)
  if not M[name] then
    core.error('Action "%s" is not defined.', name)
    return
  end

  local vfiler = VFiler.get(vim.fn.bufnr())
  if not vfiler then
    core.error('Buffer does not exist.')
    return
  end
  M[name](vfiler.context, vfiler.view, ...)
end

function M.start(configs)
  local vfiler = VFiler.new(configs)
  M.cd(vfiler.context, vfiler.view, configs.path)
  move_cursor(2)
end

function M.undefine(name)
  M[name] = nil
end

------------------------------------------------------------------------------
-- actions
------------------------------------------------------------------------------
function M.cd(context, view, path)
  -- special path
  if path == '..' then
    -- change parent directory
    path = vim.fn.fnamemodify(context.root.path, ':h:h')
  end
  context:switch(path)
  view:draw(context)
end

function M.close_tree(context, view, lnum)
  lnum = lnum or vim.fn.line('.')
  local item = view:get_item(lnum)

  local target = (item.isdirectory and item.opened) and item or item.parent
  target:close()

  view:draw(context)

  local cursor = view:indexof(target)
  if cursor then
    move_cursor(cursor)
  end
end

function M.close_tree_or_cd(context, view, lnum)
  lnum = lnum or vim.fn.line('.')
  local item = view:get_item(lnum)
  if item.level <= 1 and not item.opened then
    M.cd(context, view, '..')
  else
    M.close_tree(context, view, lnum)
  end
end

function M.change_drive(context, view)
  if context.extension then
    return
  end

  local drives = detect_drives()
  if #drives == 0 then
    return
  end

  local root = core.get_root_path(context.root.path)
  local cursor = 1
  for i, drive in ipairs(drives) do
    if drive == root then
      cursor = i
      break
    end
  end

  local menu = ExtensionMenu.new {
    name = 'Select Drive',

    on_selected = function(item)
      if root ~= item then
        M.cd(context, view, item)
      end
    end,

    on_quit = function()
      context.extension = nil
    end,
  }

  menu:start(drives, cursor)
  context.extension = menu
end

function M.change_sort(context, view)
  if context.extension then
    return
  end

  local sort_types = sort.types()
  local cursor = 1
  for i, type in ipairs(sort_types) do
    if type == context.sort then
      cursor = i
      break
    end
  end

  local menu = ExtensionMenu.new {
    name = 'Select Sort',

    on_selected = function(item)
      if context.sort ~= item then
        context:change_sort(item)
        view:draw(context)
      end
    end,

    on_quit = function()
      context.extension = nil
    end,
  }

  menu:start(sort_types, cursor)
  context.extension = menu
end

function M.delete(context, view)
  local selected = view:selected_items()
  if #selected == 0 then
    local lnum = vim.fn.line('.')
    if lnum == 1 then
      return
    end
    selected = {view:get_item(lnum)}
  end

  local prompt = 'Are you sure you want to delete? - '
  if #selected > 1 then
    prompt = prompt .. #selected .. ' files'
  else
    prompt = prompt .. selected[1].name
  end

  local choice = cmdline.confirm(
    prompt,
    {cmdline.choice.YES, cmdline.choice.NO},
    2
    )
  if choice ~= cmdline.choice.YES then
    return
  end

  -- delete files
  local deleted = {}
  for _, item in ipairs(selected) do
    if item:delete() then
      table.insert(deleted, item)
    end
  end

  if #deleted == 0 then
    return
  elseif #deleted == 1 then
    core.info('Deleted - %s', deleted[1].name)
  else
    core.info('Deleted - %d files', #deleted)
  end
  view:draw(context)
end

function M.new_directory(context, view, lnum)
  lnum = lnum or vim.fn.line('.')
  local item = view:get_item(lnum)
  local dir = (item.isdirectory and item.opened) and item or item.parent

  cmdline.input_multiple('New directory names?',
    function(contents)
      local created = {}
      for _, name in ipairs(contents) do
        local path = dir.path .. name
        if vim.fn.isdirectory(path) ~= 0 then
          core.warning('Skipped, "%s" already exists.', name)
        else
          local new = Directory.create(path)
          if new then
            dir:add(new, context.sort)
            table.insert(created, name)
          else
            core.error('Failed to create a "%s" file', name)
          end
        end
      end

      if #created == 0 then
        return
      end
      if #created == 1 then
        core.info('Created - %s', created[1])
      else
        core.info('Created - %d directories', #created)
      end
      view:draw(context)
    end
    )
end

function M.new_file(context, view, lnum)
  lnum = lnum or vim.fn.line('.')
  local item = view:get_item(lnum)
  local dir = (item.isdirectory and item.opened) and item or item.parent

  cmdline.input_multiple('New file names?',
    function(contents)
      local created = {}
      for _, name in ipairs(contents) do
        local path = dir.path .. name
        if vim.fn.filereadable(path) ~= 0 then
          core.warning('Skipped, "%s" already exists', name)
        else
          local file = File.create(path)
          if file then
            dir:add(file, context.sort)
            table.insert(created, name)
          else
            core.error('Failed to create a "%s" file', name)
          end
        end
      end

      if #created == 0 then
        return
      end
      if #created == 1 then
        core.info('Created - %s', created[1])
      else
        core.info('Created - %d files', #created)
      end
      view:draw(context)
    end
    )
end

function M.move_cursor_bottom(context, view)
  move_cursor(view:num_lines())
end

function M.move_cursor_down(context, view, loop)
  local lnum = vim.fn.line('.') + 1
  local num_end = view:num_lines()
  if lnum > num_end then
    -- the meaning of "2" is to skip the header line
    lnum = loop and 2 or num_end
  end
  move_cursor(lnum)
end

function M.move_cursor_top(context, view)
  move_cursor(2)
end

function M.move_cursor_up(context, view, loop)
  local lnum = vim.fn.line('.') - 1
  if lnum <= 1 then
    -- the meaning of "2" is to skip the header line
    lnum = loop and view:num_lines() or 2
  end
  move_cursor(lnum)
end

function M.open(context, view, lnum)
  lnum = lnum or vim.fn.line('.')
  local item = view:get_item(lnum)
  if not item then
    core.warning('Item does not exist.')
    return
  end

  if item.isdirectory then
    M.cd(context, view, item.path)
  else
    vim.command('edit ' .. item.path)
  end
end

function M.open_tree(context, view, lnum)
  lnum = lnum or vim.fn.line('.')
  local item = view:get_item(lnum)

  if not item.isdirectory or item.opened then
    return
  end
  item:open(context.sort)
  view:draw(context)
  move_cursor(lnum + 1)
end

function M.quit(context, view)
  VFiler.delete(view.bufnr)
end

function M.redraw(context, view)
  view:draw(context)
end

function M.rename(context, view)
  local selected = view:selected_items()
  if #selected == 0 then
    local lnum = vim.fn.line('.')
    if lnum == 1 then
      return
    end
    selected = {view:get_item(lnum)}
  end

  if #selected > 1 then
    M._rename_files(context, view, selected)
  else
    M._rename_one_file(context, view, selected[1])
  end
end

function M.switch_to_filer(context, view)
  local current = VFiler.get_current()
  -- already linked
  if current.linked then
    current.linked:open('right')
    return
  end

  core.open_window('right')
  local filer = VFiler.new(current.configs)
  M.cd(filer.context, filer.view, context.root.path)
  filer:link(current)
end

function M.toggle_show_hidden(context, view)
  view.show_hidden_files = not view.show_hidden_files
  view:draw(context)
end

function M.toggle_select(context, view, after_cursor, lnum)
  lnum = lnum or vim.fn.line('.')
  local item = view:get_item(lnum)
  item.selected = not item.selected
  view:redraw_line(lnum)

  -- move cursor
  if after_cursor == 'up' then
    M.move_cursor_up(context, view)
  elseif after_cursor == 'down' then
    M.move_cursor_down(context, view)
  end
end

function M._rename_files(context, view, targets)
  if context.extension then
    return
  end

  local ext = ExtensionRename.new {
    on_execute = function(items, renames)
      local num_renamed = 0
      local parents = {}
      for i = 1, #items do
        local item = items[i]
        local rename = renames[i]
        local path = item.parent.path .. '/' .. rename

        local result = true
        if vim.fn.filereadable(path) == 1 then
          if cmdline.util.confirm_overwrite(rename) == cmdline.choice.YES then
            result = item:rename(rename)
          end
        else
          result = item:rename(rename)
        end

        if result then
          num_renamed = num_renamed + 1
          parents[item.parent.path] = item.parent
        end
      end

      if num_renamed > 0 then
        core.info('Renamed - %d files', num_renamed)
        for _, parent in pairs(parents) do
          parent:sort(context.sort, false)
        end
        view:draw(context)
      end
    end,

    on_quit = function()
      context.extension = nil
    end,
  }

  ext:start(targets, 1)
  context.extension = ext
end

function M._rename_one_file(context, view, target)
  local name = target.name
  local rename = cmdline.input('New file name - ' .. name, name , 'file')
  if #rename == 0 then
    return -- Canceled
  end

  -- Check overwrite
  local path = target.parent.path .. '/' .. rename
  if vim.fn.filereadable(path) == 1 then
    if cmdline.util.confirm_overwrite(rename) ~= cmdline.choice.YES then
      return
    end
  end

  if not target:rename(rename) then
    return
  end

  core.info('Renamed - %s -> %s', name, rename)
  target.parent:sort(context.sort, false)
  view:draw(context)
end

return M
