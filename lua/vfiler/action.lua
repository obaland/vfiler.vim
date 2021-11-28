local core = require 'vfiler/core'
local cmdline = require 'vfiler/cmdline'
local sort = require 'vfiler/sort'
local vim = require 'vfiler/vim'

local Clipboard = require 'vfiler/clipboard'
local Menu = require 'vfiler/extensions/menu'
local Rename = require 'vfiler/extensions/rename'
local Directory = require 'vfiler/items/directory'
local File = require 'vfiler/items/file'
local VFiler = require 'vfiler/vfiler'

local M = {}

local function cd(vfiler, dirpath)
  local context = vfiler.context
  if context.root and context.root.path == dirpath then
    -- Same directory path
    return
  end

  local current = vfiler.view:get_current()
  if current then
    context:save(current.path)
  end
  local path = context:switch(dirpath)
  vfiler:draw()
  vfiler.view:move_cursor(path)
end

local function create_files(dest, contents, create)
  local created = {}
  for _, name in ipairs(contents) do
    local filepath = core.path.join(dest.path, name)
    local new = create(dest, name, filepath)
    if new then
      dest:add(new)
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

local function detect_drives()
  if not core.is_windows then
    return {}
  end
  local drives = {}
  for byte = ('A'):byte(), ('Z'):byte() do
    local drive = string.char(byte) .. ':/'
    if core.path.isdirectory(drive) then
      table.insert(drives, drive)
    end
  end
  return drives
end

local choose_keys = {
  'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l',
  'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',
  '1', '2', '3', '4', '5', '6', '7', '8', '9', '0',
}

local function choose_window_statusline(winwidth, char)
  local caption_width = winwidth / 4
  local padding = (' '):rep(math.ceil(caption_width / 2))
  local margin = (' '):rep(math.ceil((winwidth - caption_width) / 2))
  return ('%s%s%s%s%s%s%s'):format(
    '%#StatusLine#', margin,
    '%#vfilerStatusLine_ChooseWindowKey#', padding, char, padding,
    '%#StatusLine#'
    )
end

local function choose_window()
  local winnrs = {}
  for nr = 1, vim.fn.winnr('$') do
    if vim.get_win_option(nr, 'filetype') ~= 'vfiler' then
      table.insert(winnrs, nr)
    end
  end
  if #winnrs == 0 then
    return -1
  elseif #winnrs == 1 then
    return winnrs[1]
  end

  -- Map window keys, and save statuslines
  local keys = {}
  local winkeys = {}
  local statuslines = {}
  for _, winnr in ipairs(winnrs) do
    local key = choose_keys[winnr]
    table.insert(keys, key)
    winkeys[key] = winnr
    statuslines[winnr] = vim.get_win_option(winnr, 'statusline')
  end

  -- Save status
  local laststatus = vim.get_global_option('laststatus')
  local save_winnr = vim.fn.winnr()

  -- Choose window
  vim.set_global_option('laststatus', 2)
  for key, nr in pairs(winkeys) do
    vim.set_win_option(
      nr, 'statusline', choose_window_statusline(vim.fn.winwidth(nr), key)
      )
    vim.command('redraw')
  end

  local key = nil
  local prompt = ('choose (%s) ?'):format(table.concat(keys, '/'))
  repeat
    key = cmdline.getchar(prompt)
    if key == '<ESC>' then
      break
    end
  until winkeys[key]

  -- Restore
  vim.set_global_option('laststatus', laststatus)
  for nr, statusline in pairs(statuslines) do
    vim.set_win_option(nr, 'statusline', statusline)
    vim.command('redraw')
  end
  core.window.move(save_winnr)

  return key == '<ESC>' and nil or winkeys[key]
end

local function rename_files(vfiler, targets)
  if vfiler.context.extension then
    return
  end

  local ext = Rename.new {
    filer = vfiler,
    on_execute = function(filer, items, renames)
      local renamed = {}
      local num_renamed = 0
      local parents = {}
      for i = 1, #items do
        local item = items[i]
        local rename = renames[i]

        if item:rename(rename) then
          table.insert(renamed, item)
          num_renamed = num_renamed + 1
          parents[item.parent.path] = item.parent
          item.selected = false
        end
      end

      if #renamed > 0 then
        core.message.info('Renamed - %d files', #renamed)
        for _, parent in pairs(parents) do
          parent:sort(filer.context.sort, false)
        end
        M.reload(filer)
        filer.view:move_cursor(renamed[1].path)
      end
    end,
  }

  ext:start(targets)
end

local function rename_one_file(vfiler, target)
  local name = target.name
  local rename = cmdline.input('New file name - ' .. name, name , 'file')
  if #rename == 0 then
    return -- Canceled
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
  target.parent:sort(vfiler.context.sort, false)
  vfiler:draw()
end

------------------------------------------------------------------------------
-- Interfaces
------------------------------------------------------------------------------

function M.open_file(vfiler, path, direction)
  if direction == 'choose' then
    local winnr = choose_window()
    if not winnr then
      return
    elseif winnr < 0 then
      core.window.open('right')
    else
      core.window.move(winnr)
    end
  elseif direction ~= 'edit' then
    core.window.open(direction)
  end

  if core.path.isdirectory(path) then
    if direction == 'edit' then
      cd(vfiler, path)
      return
    end

    local newfiler = VFiler.find_hidden(vfiler.context.name)
    if newfiler then
      newfiler:open()
      newfiler:reset(vfiler.context)
    else
      local context = vfiler.context:duplicate()
      newfiler = VFiler.new(context)
    end
    newfiler:start(path)
  else
    core.window.open('edit', path)
  end
end

------------------------------------------------------------------------------
-- actions
------------------------------------------------------------------------------

function M.clear_selected_all(vfiler)
  for _, item in ipairs(vfiler.view:selected_items()) do
    item.selected = false
  end
  vfiler:redraw()
end

function M.close_tree(vfiler)
  local item = vfiler.view:get_current()
  local target = (item.isdirectory and item.opened) and item or item.parent

  target:close()
  vfiler:draw()
  vfiler.view:move_cursor(target.path)
end

function M.close_tree_or_cd(vfiler)
  local item = vfiler.view:get_current()
  local level = item.level
  if level == 0 or (level <= 1 and not item.opened) then
    local path = vfiler.context.root.path
    cd(vfiler, vfiler.context:parent_path())
    vfiler.view:move_cursor(path)
  else
    M.close_tree(vfiler)
  end
end

function M.change_sort(vfiler)
  if vfiler.context.extension then
    return
  end

  local menu = Menu.new {
    filer = vfiler,
    name = 'Select Sort',

    on_selected = function(filer, sort_type)
      if filer.context.sort == sort_type then
        return
      end

      local item = filer.view:get_current()
      filer.context:change_sort(sort_type)
      filer:draw()
      filer.view:move_cursor(item.path)
    end,
  }

  menu:start(sort.types(), vfiler.context.sort_type)
end

function M.change_to_parent(vfiler)
  cd(vfiler, vfiler.context:parent_path())
end

function M.copy(vfiler)
  local selected = vfiler.view:selected_items()
  if #selected == 0 then
    return
  end

  vfiler.context.clipboard = Clipboard.copy(selected)
  if #selected == 1 then
    core.message.info('Copy to the clipboard - %s', selected[1].name)
  else
    core.message.info('Copy to the clipboard - %d files', #selected)
  end

  -- clear selected mark
  for _, item in ipairs(selected) do
    item.selected = false
  end
  vfiler:redraw()
end

function M.copy_to_filer(vfiler)
  local selected = vfiler.view:selected_items()
  if #selected == 0 then
    return
  end
  local linked = vfiler.context.linked
  if not (linked and linked:displayed()) then
    -- Copy to clipboard
    M.copy(vfiler)
    return
  end

  -- Copy to linked filer
  local cb = Clipboard.copy(selected)
  cb:paste(linked.context.root)
  linked:open()
  linked:draw()

  -- Return to current
  vfiler:open()

  -- clear selected mark
  for _, item in ipairs(selected) do
    item.selected = false
  end
  vfiler:redraw()
end

function M.delete(vfiler)
  local selected = vfiler.view:selected_items()
  if #selected == 0 then
    return
  end

  local prompt = 'Are you sure you want to delete? - '
  if #selected > 1 then
    prompt = prompt .. #selected .. ' files'
  else
    prompt = prompt .. selected[1].name
  end

  local choices = {cmdline.choice.YES, cmdline.choice.NO}
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
  vfiler:draw()
end

function M.execute_file(vfiler)
  local item = vfiler.view:get_current()
  if item then
    core.file.execute(item.path)
  else
    core.message.error('File does not exist.')
  end
end

function M.jump_to_directory(vfiler)
  local dirpath = cmdline.input('Jump to?', '', 'dir')
  if #dirpath == 0 then
    return
  end
  dirpath = core.path.normalize(dirpath)
  if not core.path.isdirectory(dirpath) then
    core.message.error('Not exists the "%s" path.', dirpath)
    return
  end
  cd(vfiler, dirpath)
  vim.command('echo') -- clear prompt message
end

function M.jump_to_home(vfiler)
  local dirpath = vim.fn.expand('~')
  cd(vfiler, dirpath)
end

function M.jump_to_root(vfiler)
  local dirpath = core.path.root(vfiler.context.root.path)
  cd(vfiler, dirpath)
end

function M.latest_update(vfiler)
  local root = vfiler.context.root
  if vim.fn.getftime(root.path) > root.time then
    M.reload(vfiler)
    return
  end

  local view = vfiler.view
  for i = view:top_lnum(), view:num_lines() do
    local item = view:get_item(i)
    if item.isdirectory and item.opened then
      if vim.fn.getftime(item.path) > item.time then
        M.reload(vfiler)
        return
      end
    end
  end
end

function M.loop_cursor_down(vfiler)
  local lnum = vim.fn.line('.') + 1
  local num_end = vfiler.view:num_lines()
  if lnum > num_end then
    core.cursor.move(vfiler.view:top_lnum())
    -- Correspondence to show the header line
    -- when moving to the beginning of the line.
    vim.command('normal zb')
  else
    core.cursor.move(lnum)
  end
end

function M.loop_cursor_up(vfiler)
  local lnum = vim.fn.line('.') - 1
  if lnum < vfiler.view:top_lnum() then
    lnum = vfiler.view:num_lines()
  end
  core.cursor.move(lnum)
end

function M.move(vfiler)
  local selected = vfiler.view:selected_items()
  if #selected == 0 then
    return
  end

  vfiler.context.clipboard = Clipboard.move(selected)
  if #selected == 1 then
    core.message.info('Move to the clipboard - %s', selected[1].name)
  else
    core.message.info('Move to the clipboard - %d files', #selected)
  end

  -- clear selected mark
  for _, item in ipairs(selected) do
    item.selected = false
  end
  vfiler:redraw()
end

function M.move_cursor_bottom(vfiler)
  core.cursor.move(vfiler.view:num_lines())
end

function M.move_cursor_down(vfiler)
  local lnum = vim.fn.line('.') + 1
  core.cursor.move(lnum)
end

function M.move_cursor_top(vfiler)
  core.cursor.move(vfiler.view:top_lnum())
  -- Correspondence to show the header line
  -- when moving to the beginning of the line.
  vim.command('normal zb')
end

function M.move_cursor_up(vfiler)
  local lnum = math.max(vfiler.view:top_lnum(), vim.fn.line('.') - 1)
  core.cursor.move(lnum)
end

function M.move_to_filer(vfiler)
  local selected = vfiler.view:selected_items()
  if #selected == 0 then
    return
  end
  local linked = vfiler.context.linked
  if not (linked and linked:displayed()) then
    -- Move to clipboard
    M.move(vfiler)
    return
  end

  -- Move to linked filer
  local cb = Clipboard.move(selected)
  cb:paste(linked.context.root)
  linked:open()
  linked:draw()

  vfiler:open()
  vfiler:draw()
end

function M.new_directory(vfiler)
  local item = vfiler.view:get_current()
  local dir = (item.isdirectory and item.opened) and item or item.parent

  local function create_directory(dest, name, filepath)
    if core.path.isdirectory(filepath) then
      if cmdline.util.confirm_overwrite(name) ~= cmdline.choice.YES then
        return false
      end
    elseif core.is_windows and core.path.filereadable(filepath) then
      core.message.warning(
        'Not created. "%s" file with the same name already exists.', name
        )
      return false
    end
    return Directory.create(filepath, dest.sort_type)
  end

  cmdline.input_multiple('New directory names?',
    function(contents)
      local created = create_files(dir, contents, create_directory)
      if created then
        vfiler:draw()
        -- move the cursor to the created item path
        vfiler.view:move_cursor(created[1].path)
      end
    end)
end

function M.new_file(vfiler)
  local item = vfiler.view:get_current()
  local dir = (item.isdirectory and item.opened) and item or item.parent

  local function create_file(dest, name, filepath)
    if core.path.filereadable(filepath) then
      if cmdline.util.confirm_overwrite(name) ~= cmdline.choice.YES then
        return false
      end
    elseif core.is_windows and core.path.isdirectory(filepath) then
      core.message.warning(
        'Not created. "%s" directory with the same name already exists.', name
        )
      return false
    end
    return File.create(filepath)
  end

  cmdline.input_multiple('New file names?',
    function(contents)
      local created = create_files(dir, contents, create_file)
      if created then
        vfiler:draw()
        -- move the cursor to the created item path
        vfiler.view:move_cursor(created[1].path)
      end
    end)
end

function M.open(vfiler)
  local path = vfiler.view:get_current().path
  M.open_file(vfiler, path, 'edit')
end

function M.open_by_choose(vfiler)
  local path = vfiler.view:get_current().path
  M.open_file(vfiler, path, 'choose')
end

function M.open_by_choose_or_cd(vfiler)
  local item = vfiler.view:get_current()
  if item.isdirectory then
    cd(vfiler, item.path)
  else
    M.open_file(vfiler, item.path, 'choose')
  end
end

function M.open_by_split(vfiler)
  local path = vfiler.view:get_current().path
  M.open_file(vfiler, path, 'bottom')
end

function M.open_by_tabpage(vfiler)
  local path = vfiler.view:get_current().path
  M.open_file(vfiler, path, 'tab')
end

function M.open_by_vsplit(vfiler)
  local path = vfiler.view:get_current().path
  M.open_file(vfiler, path, 'right')
end

function M.open_tree(vfiler)
  local lnum = vim.fn.line('.')
  local item = vfiler.view:get_item(lnum)
  if not item.isdirectory or item.opened then
    return
  end
  item:open()
  vfiler:draw()
  core.cursor.move(lnum + 1)
end

function M.open_tree_recursive(vfiler)
  local lnum = vim.fn.line('.')
  local item = vfiler.view:get_item(lnum)
  if not item.isdirectory or item.opened then
    return
  end
  item:open(true)
  vfiler:draw()
  core.cursor.move(lnum + 1)
end

function M.paste(vfiler)
  local cb = vfiler.context.clipboard
  if not cb then
    core.message.warning('No clipboard')
    return
  end

  local item = vfiler.view:get_current()
  local dest = (item.isdirectory and item.opened) and item or item.parent
  if cb:paste(dest) and cb.keep then
    vfiler.context.clipboard = nil
  end
  vfiler:draw()
end

function M.quit(vfiler)
  vfiler:quit()
end

function M.redraw(vfiler)
  vfiler:draw()
end

function M.redraw_all(vfiler)
  for _, filer in ipairs(VFiler.get_displays()) do
    M.redraw(filer)
  end
end

function M.reload(vfiler)
  local context = vfiler.context
  context:save(vfiler.view:get_current().path)
  context:switch(context.root.path)
  vfiler:draw()
end

function M.reload_all(vfiler)
  for _, filer in ipairs(VFiler.get_displays()) do
    M.reload(filer)
  end
end

function M.rename(vfiler)
  local selected = vfiler.view:selected_items()
  if #selected == 1 then
    rename_one_file(vfiler, selected[1])
  elseif #selected > 1 then
    rename_files(vfiler, selected)
  end
end

function M.switch_to_drive(vfiler)
  if vfiler.context.extension then
    return
  end

  local drives = detect_drives()
  if #drives == 0 then
    return
  end

  local root = core.path.root(vfiler.context.root.path)
  local menu = Menu.new {
    filer = vfiler,
    name = 'Select Drive',

    on_selected = function(filer, drive)
      if root == drive then
        return
      end

      local path = filer.view:get_current().path
      filer.context:save(path)
      path = filer.context:switch_drive(drive)
      filer.view:draw(filer.context)
      filer.view:move_cursor(path)
    end,
  }

  menu:start(drives, root)
end

function M.switch_to_filer(vfiler)
  local linked = vfiler.context.linked
  -- already linked
  if linked then
    linked:open('right')
    return
  end

  -- create link to filer
  local lnum = vim.fn.line('.')
  local newfiler = VFiler.find_hidden(vfiler.context.name)
  if newfiler then
    newfiler:open('right')
    newfiler:reset(vfiler.context)
  else
    core.window.open('right')
    local context = vfiler.context:duplicate()
    newfiler = VFiler.new(context)
  end
  newfiler:link(vfiler)
  newfiler:draw()
  core.cursor.move(lnum)

  -- redraw current
  vfiler:open()
  vfiler:redraw()

  newfiler:open() -- return other filer
end

function M.sync_with_current_filer(vfiler)
  local linked = vfiler.context.linked
  if not (linked and linked:displayed()) then
    return
  end

  linked:open()
  linked.context:sync(vfiler.context)
  linked:draw()
  vfiler:open() -- return current window
end

function M.toggle_show_hidden(vfiler)
  vfiler.context.show_hidden_files = not vfiler.context.show_hidden_files
  vfiler:draw()
end

function M.toggle_select(vfiler)
  local lnum = vim.fn.line('.')
  local item = vfiler.view:get_item(lnum)
  item.selected = not item.selected
  vfiler.view:redraw_line(lnum)
end

function M.toggle_select_all(vfiler)
  local root = vfiler.context.root
  for _, item in ipairs(root:walk()) do
    item.selected = not item.selected
  end
  vfiler:redraw()
end

function M.toggle_select_down(vfiler)
  M.toggle_select(vfiler)
  M.move_cursor_down(vfiler)
end

function M.toggle_select_up(vfiler)
  M.toggle_select(vfiler)
  M.move_cursor_up(vfiler)
end

function M.yank_name(vfiler)
  local selected = vfiler.view:selected_items()
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
  vfiler:redraw()
end

function M.yank_path(vfiler)
  local selected = vfiler.view:selected_items()
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
  vfiler:redraw()
end

return M
