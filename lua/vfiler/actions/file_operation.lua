local api = require('vfiler/actions/api')
local buffer = require('vfiler/actions/buffer')
local cmdline = require('vfiler/libs/cmdline')
local core = require('vfiler/libs/core')
local fs = require('vfiler/libs/filesystem')

local Clipboard = require('vfiler/clipboard')
local Rename = require('vfiler/extensions/rename')
local VFiler = require('vfiler/vfiler')

local M = {}

local function create_files(dest, contents, create)
  local created = {}
  for _, name in ipairs(contents) do
    local filepath = core.path.join(dest.path, name)
    local new = create(dest, name, filepath)
    if new then
      table.insert(created, new)
    elseif new == nil then
      core.message.error('Failed to create a "%s" file', name)
    end
  end

  if #created == 0 then
    return nil
  end

  if #created == 1 then
    core.message.info('Created - "%s" file', created[1].name)
  else
    core.message.info('Created - %d files', #created)
  end
  return created
end

local function rename_files(vfiler, context, view, targets)
  local rename = Rename.new(vfiler, {
    initial_items = targets,
    on_execute = function(filer, c, v, items, renames)
      local renamed = {}
      local num_renamed = 0
      for i = 1, #items do
        local item = items[i]
        local rename = renames[i]

        if item:rename(rename) then
          table.insert(renamed, item)
          num_renamed = num_renamed + 1
          item.selected = false
        end
      end

      if #renamed > 0 then
        core.message.info('Renamed - %d files', #renamed)
        VFiler.foreach(buffer.reload)
        v:move_cursor(renamed[1].path)
      end
    end,
  })
  api.start_extension(vfiler, context, view, rename)
end

local function rename_one_file(vfiler, context, view, target)
  local name = target.name
  local rename = cmdline.input('New file name - ' .. name, name, 'file')
  if #rename == 0 then
    -- canceled
    return
  end

  -- Check overwrite
  local filepath = core.path.join(target.parent.path, rename)
  if core.path.exists(filepath) == 1 then
    if cmdline.util.confirm_overwrite(rename) ~= cmdline.choice.YES then
      return
    end
  end

  if not target:rename(rename) then
    return
  end

  core.message.info('Renamed - "%s" -> "%s"', name, rename)
  VFiler.foreach(buffer.reload)
end

function M.copy(vfiler, context, view)
  local selected = view:selected_items()
  if #selected == 0 then
    return
  end

  context.clipboard = Clipboard.copy(selected)
  if #selected == 1 then
    core.message.info('Copy to the clipboard - %s', selected[1].name)
  else
    core.message.info('Copy to the clipboard - %d files', #selected)
  end

  -- clear selected mark
  for _, item in ipairs(selected) do
    item.selected = false
  end
  view:redraw()
end

function M.copy_to_filer(vfiler, context, view)
  local selected = view:selected_items()
  if #selected == 0 then
    return
  end
  local linked = context.linked
  if not (linked and linked:visible()) then
    -- Copy to clipboard
    vfiler:do_action(M.copy)
    return
  end

  -- Copy to linked filer
  local cb = Clipboard.copy(selected)
  cb:paste(linked:get_root_item())

  -- clear selected mark
  for _, item in ipairs(selected) do
    item.selected = false
  end
  VFiler.foreach(buffer.reload)
end

function M.delete(vfiler, context, view)
  local selected = view:selected_items()
  if #selected == 0 then
    return
  end

  local prompt = 'Are you sure you want to delete? - '
  if #selected > 1 then
    prompt = prompt .. #selected .. ' files'
  else
    prompt = prompt .. selected[1].name
  end

  local choices = { cmdline.choice.YES, cmdline.choice.NO }
  if cmdline.confirm(prompt, choices, 2) ~= cmdline.choice.YES then
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
    core.message.info('Deleted - %s', deleted[1].name)
  else
    core.message.info('Deleted - %d files', #deleted)
  end
  VFiler.foreach(buffer.reload)
end

function M.execute_file(vfiler, context, view)
  local item = view:get_item()
  if item then
    fs.execute(item.path)
  else
    core.message.error('File does not exist.')
  end
end

function M.move(vfiler, context, view)
  local selected = view:selected_items()
  if #selected == 0 then
    return
  end

  context.clipboard = Clipboard.move(selected)
  if #selected == 1 then
    core.message.info('Move to the clipboard - %s', selected[1].name)
  else
    core.message.info('Move to the clipboard - %d files', #selected)
  end

  -- clear selected mark
  for _, item in ipairs(selected) do
    item.selected = false
  end
  view:redraw()
end

function M.move_to_filer(vfiler, context, view)
  local selected = view:selected_items()
  if #selected == 0 then
    return
  end
  local linked = context.linked
  if not (linked and linked:visible()) then
    -- Move to clipboard
    vfiler:do_action(M.move)
    return
  end

  -- Move to linked filer
  local cb = Clipboard.move(selected)
  cb:paste(linked:get_root_item())
  VFiler.foreach(buffer.reload)
end

function M.new_directory(vfiler, context, view)
  local item = view:get_item()
  local dir = item.opened and item or item.parent

  local function create_directory(dest, name, filepath)
    if core.path.is_directory(filepath) then
      if cmdline.util.confirm_overwrite(name) ~= cmdline.choice.YES then
        return false
      end
    elseif core.is_windows and core.path.filereadable(filepath) then
      core.message.warning(
        'Not created. "%s" file with the same name already exists.',
        name
      )
      return false
    end
    return dest:create_directory(name)
  end

  cmdline.input_multiple('New directory names?', function(contents)
    local created = create_files(dir, contents, create_directory)
    if created then
      VFiler.foreach(buffer.reload)
      -- move the cursor to the created item path
      view:move_cursor(created[1].path)
    end
  end)
end

function M.new_file(vfiler, context, view)
  local item = view:get_item()
  local dir
  if not item then
    -- If there is no header line and the current root directory is empty.
    dir = context.root
  elseif item.opened then
    dir = item
  else
    dir = item.parent
  end

  local function create_file(dest, name, filepath)
    if core.path.filereadable(filepath) then
      if cmdline.util.confirm_overwrite(name) ~= cmdline.choice.YES then
        return false
      end
    elseif core.is_windows and core.path.is_directory(filepath) then
      core.message.warning(
        'Not created. "%s" directory with the same name already exists.',
        name
      )
      return false
    end
    return dest:create_file(name)
  end

  cmdline.input_multiple('New file names?', function(contents)
    local created = create_files(dir, contents, create_file)
    if created then
      VFiler.foreach(buffer.reload)
      -- move the cursor to the created item path
      view:move_cursor(created[1].path)
    end
  end)
end

function M.paste(vfiler, context, view)
  local cb = context.clipboard
  if not cb then
    core.message.warning('No clipboard')
    return
  end

  local item = view:get_item()
  local dest = item.opened and item or item.parent
  if cb:paste(dest) and cb.keep then
    context.clipboard = nil
  end
  VFiler.foreach(buffer.reload)
end

function M.rename(vfiler, context, view)
  local selected = view:selected_items()
  if #selected == 1 then
    rename_one_file(vfiler, context, view, selected[1])
  elseif #selected > 1 then
    if view:type() == 'floating' then
      core.message.warning(
        'The floating window does not support multiple renaming.'
      )
    else
      rename_files(vfiler, context, view, selected)
    end
  end
end

return M
