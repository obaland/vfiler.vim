local utils = require('vfiler/actions/utilities')
local buffer = require('vfiler/actions/buffer')
local clipboard = require('vfiler/clipboard')
local cmdline = require('vfiler/libs/cmdline')
local core = require('vfiler/libs/core')
local fs = require('vfiler/libs/filesystem')
local vim = require('vfiler/libs/vim')

local VFiler = require('vfiler/vfiler')

local M = {}

local function resolve_destination_directory(context, view)
  local item = view:get_item()
  if not item then
    -- Empty views still allow creating and pasting items into the root.
    return context.root
  end
  return item.opened and item or item.parent
end

local function directory_key(path)
  local key = core.path.normalize(path):gsub('/+$', '') .. '/'
  if core.is_windows or core.is_mac then
    key = vim.fn.tolower(key)
  end
  return key
end

local function contains_changed_directory(path, changed)
  local key = directory_key(path)
  for directory in pairs(changed) do
    if directory:sub(1, #key) == key then
      return true
    end
  end
  return false
end

local function has_changed_link(directory, changed)
  for _, child in pairs(directory.child_directories or {}) do
    if child.opened then
      if
        child.link
        and contains_changed_directory(vim.fn.resolve(child.path), changed)
      then
        return true
      end
      if has_changed_link(child, changed) then
        return true
      end
    end
  end
  return false
end

local function reload_changed_directories(vfiler, parents)
  if not parents then
    VFiler.foreach(buffer.reload)
    return
  end

  local changed = {}
  for parent in pairs(parents) do
    changed[directory_key(parent)] = true
    changed[directory_key(vim.fn.resolve(parent))] = true
  end

  VFiler.foreach(function(filer, context, view)
    local root = context.root
    if
      filer == vfiler
      or view:has_column('git')
      or contains_changed_directory(root.path, changed)
      or contains_changed_directory(vim.fn.resolve(root.path), changed)
      or has_changed_link(root, changed)
    then
      buffer.reload(filer, context, view)
    end
  end)
end

local function reload_after_create(vfiler, created)
  local parents = {}
  for _, item in ipairs(created) do
    parents[core.path.parent(item.path)] = true
    if item.link then
      parents[core.path.parent(vim.fn.resolve(item.path))] = true
    end
  end
  reload_changed_directories(vfiler, parents)
end

local function add_file_parents(parents, item, old_path)
  if not parents or item.type ~= 'file' or item.link then
    return nil
  end
  parents[core.path.parent(item.path)] = true
  if old_path then
    parents[core.path.parent(old_path)] = true
  end
  return parents
end

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
  local Rename = require('vfiler/extensions/rename')
  local rename = Rename.new(vfiler, {
    initial_items = targets,
    on_execute = function(filer, c, v, items, renames)
      local renamed = {}
      local parents = {}
      local num_renamed = 0
      for i = 1, #items do
        local item = items[i]
        local rename = renames[i]
        local old_path = item.path

        if item:rename(rename) then
          parents = add_file_parents(parents, item, old_path)
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
  utils.start_extension(vfiler, context, view, rename)
end

local function rename_one_file(vfiler, context, view, target)
  local name = target.name
  local rename = cmdline.input('New file name - ' .. name, name, 'file')
  if #rename == 0 or rename == name then
    -- canceled or unchanged
    return
  end

  -- Check overwrite
  local filepath = core.path.join(target.parent.path, rename)
  if core.path.exists(filepath) then
    if cmdline.util.confirm_overwrite(rename) ~= cmdline.choice.YES then
      return
    end
  end

  local old_path = target.path
  if not target:rename(rename) then
    return
  end

  core.message.info('Renamed - "%s" -> "%s"', name, rename)
  reload_changed_directories(vfiler, add_file_parents({}, target, old_path))
end

function M.copy(vfiler, context, view)
  local selected = view:selected_items()
  if #selected == 0 then
    return
  end

  clipboard.copy_to_clipboard(selected)
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
  local _, parents = clipboard.copy(selected, linked:get_root_item())

  -- clear selected mark
  for _, item in ipairs(selected) do
    item.selected = false
  end
  reload_changed_directories(vfiler, parents)
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
  local parents = {}
  for _, item in ipairs(selected) do
    if item:delete() then
      parents = add_file_parents(parents, item)
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
  reload_changed_directories(vfiler, parents)
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

  clipboard.move_to_clipboard(selected)
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
  local _, parents = clipboard.move(selected, linked:get_root_item())
  reload_changed_directories(vfiler, parents)
end

function M.new_directory(vfiler, context, view)
  local dir = resolve_destination_directory(context, view)

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
      reload_after_create(vfiler, created)
      -- move the cursor to the created item path
      view:move_cursor(created[1].path)
    end
  end)
end

function M.new_file(vfiler, context, view)
  local dir = resolve_destination_directory(context, view)

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
      reload_after_create(vfiler, created)
      -- move the cursor to the created item path
      view:move_cursor(created[1].path)
    end
  end)
end

function M.paste(vfiler, context, view)
  local cb = clipboard.get_current()
  if not cb then
    core.message.warning('No clipboard')
    return
  end

  local dest = resolve_destination_directory(context, view)
  local _, parents = cb:paste(dest)
  reload_changed_directories(vfiler, parents)
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
