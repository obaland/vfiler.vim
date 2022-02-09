# Introduction

## Description

- File manager
You can perform basic operations such as selecting, creating, deleting,
copying, moving, and renaming files.
-
- Operation between multiple buffers
It can be treated as 2 window filer. This makes file operations easier to
handle.
-
- Not depends on other plugins.
It works independently without relying on other plugins.
-
- Required enough feature, lightweight operation
Aiming for the necessary and sufficient functions to increase working
efficiency and their lightweight operation.

## Requirements

vfiler.vim requires Neovim(0.5.0+) or Vim8.2+ with if_lua.

# Interface

## Commands

#### :VFiler [{options}..] [{path}]
Runs vfiler. This command reuses a buffer if a filer buffer already
exists. If you omit {path} and a filer buffer do not exist, vfiler opens
current directory. {path} needs to be a directory.
{options} are options for a filer buffer: [options](##options)

Example:
```
" Starts by specifying the buffer name and widthout adding it to the
" buffer list.
:VFiler -name=foo -no-listed /foo/bar
```

## Functions

#### vfiler.start([{dirpath}, {configs}])
Start vfiler.
If {dirpath} is nil or empty, it means that the current directory path is
specified.
{configs} is a table that stores various setting values.
For nil, the value set just before this function is called is applied.
see [configurations](##configurations).


#### vfiler.start_command({args})
Start vfiler from the command line arguments.
{args} is a command line argument string.
see [options](##options).

#### vfiler.config.setup({configs})
Setup various configuration values.
{configs} is a table, overwritten with the specified value.
The return value will be the overwritten configuration values,
and can be passed to the [vfiler.start()](####vfiler.start) function.
see [configurations](##configurations).

## Actions

#### loop_cursor_down
Switches to next line with loop.

#### loop_cursor_up
Switches to previous line with loop.

#### move_cursor_bottom
Moves the cursor to the bottom of the filer.

#### move_cursor_top
Moves the cursor to the top of the filer.

#### open
Change cursor directory or open cursor file.

#### yank_path
Yanks full path to clipboard register and unnamed register.

#### yank_name
Yanks filename to clipboard register and unnamed register.

#### open_by_tabpage
Open cursor file by tabpage.

#### open_by_split
Open cursor file by split.

#### open_by_vsplit
Open cursor file by vsplit.

#### execute_file
Execute the file with an external program.

#### open_tree
Expand the directory on the cursor.

#### open_tree_recursive
Recursively expand the directory on the cursor.

#### close_tree_or_cd
Close cursor directory tree or change to parent directory.

#### change_to_parent
Change to parent directory.

#### jump_to_home
Jump to home directory.

#### jump_to_root
Jump to root directory.

#### toggle_auto_preview
Toggle the automatic preview window.

#### toggle_preview
Toggle the preview window for the item in the current cursor. 

#### toggle_show_hidden
Toggles visible hidden files.

#### toggle_select_down
Toggles mark in cursor line and move down.

#### toggle_select_up
Toggles mark in cursor line and move up.

#### toggle_select_all
Toggles marks in all lines.

#### toggle_sort
Toggle the ascending / descending order of the current sort method.

#### clear_selected_all
Clears marks in all lines.

#### switch_to_filer
Switch the filer buffer in the tab page. If there is no buffer to switch, create it.

#### sync_with_current_filer
Synchronizes another filer current directory with current filer.

#### switch_to_drive
Switches to other drive(Windows) or mount point(Mac/Linux).

#### change_sort
Change the sort method.

#### reload
Reload filer.

#### jump_to_directory
Jump to specified directory.

#### quit
Quit the filer.

#### new_file
Creates new files. If directory tree is opened, create new files in directory tree.

#### new_directory
Make the directories.

#### delete
Delete files.

#### rename
Rename files.

#### copy
Copy files.

#### move
Move files.

#### paste
Paste files saved in the clipboard.

#### add_bookmark
Add the item in the current line to the bookmark.

#### list_bookmark
List the bookmarks.

## Options

## Key mappings

# Customization

Here are some examples of customization.

## Explorer style
In addition to the settings for Explorer,
we'll also change the actions to make it easier to use.

When starting with a command:
```
:VFiler -name=explorer -auto-cd -auto-resize -keep -layout=left
        \ -width=30 -columns=indent,icon,name
```

When string with a lua script:
```
local action = require('vfiler/action')
require('vfiler/config').setup {
  options = {
    auto_cd = true,
    auto_resize = true,
    keep = true,
    layout = 'left',
    name = 'explorer',
    width = 30,
    columns = 'indent,icon,name',
  },
}

require('vfiler').start()
```

# About

vfiler.vim is developed by obaland and licensed under the MIT License.
Visit the project page for the latest information:

<https://github.com/obaland/vfiler.vim>

I am hoping to continually improve it as far as time permits.
Welcome your requests and suggestions, so please [create an issue](https://github.com/obaland/vfiler.vim/issues/new).

==============================================================================
