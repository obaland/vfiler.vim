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
Note: It does not work in floating windows.

#### sync_with_current_filer
Synchronizes another filer current directory with current filer.
Note: It does not work in floating windows.

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

{options} are options for a filer buffer.  You may give the following parameters for an option.
You need to escape spaces with "\\".

#### -no-{option-name}
Disable {option-name} flag.
Note: If you use both {option-name} and -no-{option-name} in the same
vfiler buffer, it is undefined.

#### -auto-cd
Change the working directory while navigating with vfiler.
Default: false

#### -auto-resize
Enabled, it will automatically resize to the size specified by `width` and `height` options.
Default: false

#### -columns={column1,column2,...}
Specify the vfiler columns.
see [columns](##Columns).
Default: "indent,icon,name,mode,size,time"

#### -git-enabled
Handles Git information.
Defualt: true

#### -git-ignored
Include Git ignored files.
Defualt: true

#### -git-untracked
Include Git untracked files.
Defualt: true

#### -header
Display the header line.
Defualt: true

#### -keep
Keep the vfiler window with the open action.
Defualt: false

#### -listed
Display the vfiler buffer in the buffer list.
Defualt: true

#### -name={buffer-name}
Specifies a buffer name.
The default buffer name is blank.
Note: Buffer name must not contain spaces.

#### -new
Create new vfiler buffer.
Default: false

#### -preview-height={window-height}
The window height of the buffer whose layout is `top`, `bottom`, `floating`.
If you specify `0`, the height will be calculated automatically.
Default: 0

#### -preview-layout={type}
Specify the layout of the preview window.
Default: `floating`

    left    : Split to the left.
    right   : Split to the right.
    top     : Split to the top.
    bottom  : Split to the bottom.
    floating: Floating window.

#### -preview-width={window-width}
The window width of the buffer whose layout is `left`, `right`, `floating`.
If you specify `0`, the width will be calculated automatically.
Default: 0

#### -show-hidden-files
If enabled, Make hidden files visible by default.
Default: false

#### -layout={type}
Specify the layout of the window.
Default: `none`

    left    : Split to the left.
    right   : Split to the right.
    top     : Split to the top.
    bottom  : Split to the bottom.
    tab     : Create the new tabpage.
    floating: Floating window. Note: only Neovim
    none    : No split or floating.

#### -height={window-height}
Set the height of the window.
It is a valid value when the window is splitted or floating by
the [layout](####-layout) option etc.
Default: 30

#### -width={window-width}
Set the width of the window.
It is a valid value when the window is splitted or floating by
the [layout](####-layout) option etc.
Default: 90

#### -row={window-row}
Set the row position to display the floating window.
If `0`, it will be set automatically according to the current window size.
Note: This option is valid only when the [layout](####-layout) option is `floating`.
Default: 0

#### -col={window-column}
Set the column position to display the floating window.
If `0`, it will be set automatically according to the current window size.
Note: This option is valid only when the [layout](####-layout) option is `floating`.
Default: 0

#### -blend={value}
Enables pseudo-transparency for a floating window. Valid values are in
the range of 0 for fully opaque window (disabled) to 100 for fully
transparent background. Values between 0-30 are typically most useful.
Note: This option is valid only when the [layout](####-layout) option is `floating`.
Default: 0

#### -border={type}
Style of window border.
Note: This option is valid only when the [layout](####-layout) option is `floating`.
Default: `rounded`

#### -zindex={value}
Stacking order.
floats with higher `zindex` go on top on floats with lower indices. Must be larger than zero.
Note: This option is valid only when the [layout](####-layout) option is `floating`.
Default: 200

## Columns

#### name
File name.

#### indent
Tree indentaion.

#### icon
Icon such as directory, and marks.

#### mode
File mode.

#### size
File size.

#### time
File modified time.

#### type
File type.

#### git
Git status.

#### space
Space column for padding.

## Configurations

There are two main types of configurations, {options} and {mappings}.

#### options
Sets the behavior of vfiler.
The meaning of each option is the same as the [options](##options).

#### mappings
Associate the action with the key mapping.
Set the key string and action as a key-value pair.

Example:
```
    require('vfiler/config').setup {
      options = {
        auto_cd = false,
        columns = 'indent,icon,name,mode,size,time',
        header = true,
        listed = true,
        -- ...
        width = 90,
        height = 30,
        new = false,
        quit = true,
      },

      mappings = {
        ['.']         = action.toggle_show_hidden,
        ['<BS>']      = action.change_to_parent,
        ['<C-l>']     = action.reload,
        ['<C-p>']     = action.toggle_auto_preview,
        ['<CR>']      = action.open,
        -- ...
        ['S']         = action.change_sort,
        ['U']         = action.clear_selected_all,
        ['YY']        = action.yank_name,
      },
    }
```

## Key mappings

Following keymappings are default keymappings.

| {lhs} | {rhs} (action) |
| --- | --- |
|j|loop_cursor_down|
|k|loop_cursor_up|
|l|open_tree|
|h|close_tree_or_cd|
|gg|move_cursor_top|
|G|move_cursor_bottom|
|.|toggle_show_hidden|
|~|jump_to_home|
|\\|jump_to_root|
|o|open_tree_recursive|
|p|toggle_preview|
|t|open_by_tabpage|
|s|open_by_split|
|v|open_by_vsplit|
|x|execute_file|
|yy|yank_path|
|YY|yank_name|
|P|paste|
|L|switch_to_drive|
|S|change_sort|
|q|quit|
|<CR>|open|
|<Space>|toggle_select_down|
|<S-Space>|toggle_select_up|
|\*|toggle_select_all|
|U|clear_selected_all|
|<Tab>|switch_to_filer|
|<BS>|change_to_parent|
|<C-l>|reload|
|<C-p>|toggle_auto_preview|
|<C-r>|sync_with_current_filer|
|<C-s>|toggle_sort|
|J|jump_to_directory|
|N|new_file|
|K|new_directory|
|dd|delete|
|D|delete|
|r|rename|
|cc|copy|
|C|copy|
|mm|move|
|M|move|

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

==============================================================================
