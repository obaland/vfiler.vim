# Usage
There are two ways to start vfiler: starting from a command and starting from a Lua function.

## Command usage
```
:VFiler [{options}...] [{path}]
```
If `{path}` is not specified, it will start in the current directory.<br>
`{options}` are options for the behavior of vfiler.

### Command options
Command options are in the form starting with `-`.<br>
For flag options, prefixing them with `-no-{option-name}` disables the option.

> NOTE: If you use both `{option-name}` and `-no-{option-name}` in the same vfiler buffer, it is undefined.

Please see the [Options](##Options) for details.

### Examples
```
:VFiler -auto-cd -keep -layout=left -width=30 columns=indent,icon,name
:VFiler -no-git-enabled
```

### Command and configuration options
The names of the command options and the configuration options by `require'vfiler/config'.setup()` are very similar. <br>
Also, the meaning is exactly the same.<br>
The setting by `require'vfiler/config'.setup()` is the default setting, and the command option is different in that it overrides the default setting and starts vfiler.

### Examples
| Configuration option | Command option |
| ---- | ---- |
| name = 'buffer-name' | -name=buffer-name |
| auto_cd = true | -auto-cd |
| auto_cd = false | -no-auto-cd |
| git.ignored = true | -git-ignored |
| git.ignored = false | -no-git-ignored |

## Lua function usage
Starting vfiler with Lua function:
```lua
require'vfiler'.start(path, configs)
```
Here `path` is any directory path string. If omitted or an empty string, it will be started as the current directory.<br>
The `configs` is a configuration table with the same configuration as `require'vfiler/config'.setup()`. If you omit `configs`, the default settings will be applied. <br>
It is possible to change the behavior according to the situation by specifying it when you want to start with a setting different from the default setting.

see: [Customization](#customization) for details on the customization.

### Example
```lua
-- Start by partially changing the configurations from the default.
local action = require'vfiler/action'
local configs = {
  options = {
    name = 'myfiler',
    preview = {
      layout = 'right',
    },
  },

  mappings = {
    ['<C-l>'] = action.open_tree,
    ['<C-h>'] = action.close_tree_or_cd,
  },
}

-- Start vfiler
require'vfiler'.start(dirpath, configs)
```

# Customization

## Introduction
As a basis for configuration, you need to run `require'vfiler/config'.setup()` in your personal settings.<br>
There are two main types of configurations, `options` and `mappings`.

### vfiler setup structure
``` lua
local action = require('vfiler/action')
require('vfiler/config').setup {
  options = {
    -- Default configuration for vfiler goes here:
    -- option_key = value,
  },
  
  mappings = {
    -- Associate the action with the key mapping.
    -- Set the key string and action as a key-value pair.

    -- map actions.change_to_parent to <C-h> (default: <BS>)
    ['<C-h>'] = action.change_to_parent
  },
}
```

## Default configurations
```lua
-- following options are the default
require'vfiler/config'.setup {
  options = {
    auto_cd = false,
    auto_resize = false,
    columns = 'indent,icon,name,mode,size,time',
    header = true,
    keep = false,
    listed = true,
    name = '',
    show_hidden_files = false,
    sort = 'name',
    layout = 'none',
    width = 90,
    height = 30,
    new = false,
    quit = true,
    row = 0,
    col = 0,
    blend = 0,
    border = 'rounded',
    zindex = 200,
    git = {
      enabled = true,
      ignored = true,
      untracked = true,
    },
    preview = {
      layout = 'floating',
      width = 0,
      height = 0,
    },
  },

  mappings = {
    ['.'] = action.toggle_show_hidden,
    ['<BS>'] = action.change_to_parent,
    ['<C-l>'] = action.reload,
    ['<C-p>'] = action.toggle_auto_preview,
    ['<C-r>'] = action.sync_with_current_filer,
    ['<C-s>'] = action.toggle_sort,
    ['<CR>'] = action.open,
    ['<S-Space>'] = function(vfiler, context, view)
      action.toggle_select(vfiler, context, view)
      action.move_cursor_up(vfiler, context, view)
    end,
    ['<Space>'] = function(vfiler, context, view)
      action.toggle_select(vfiler, context, view)
      action.move_cursor_down(vfiler, context, view)
    end,
    ['<Tab>'] = action.switch_to_filer,
    ['~'] = action.jump_to_home,
    ['*'] = action.toggle_select_all,
    ['\\'] = action.jump_to_root,
    ['cc'] = action.copy_to_filer,
    ['dd'] = action.delete,
    ['gg'] = action.move_cursor_top,
    ['b'] = action.list_bookmark,
    ['h'] = action.close_tree_or_cd,
    ['j'] = action.loop_cursor_down,
    ['k'] = action.loop_cursor_up,
    ['l'] = action.open_tree,
    ['mm'] = action.move_to_filer,
    ['p'] = action.toggle_preview,
    ['q'] = action.quit,
    ['r'] = action.rename,
    ['s'] = action.open_by_split,
    ['t'] = action.open_by_tabpage,
    ['v'] = action.open_by_vsplit,
    ['x'] = action.execute_file,
    ['yy'] = action.yank_path,
    ['B'] = action.add_bookmark,
    ['C'] = action.copy,
    ['D'] = action.delete,
    ['G'] = action.move_cursor_bottom,
    ['J'] = action.jump_to_directory,
    ['K'] = action.new_directory,
    ['L'] = action.switch_to_drive,
    ['M'] = action.move,
    ['N'] = action.new_file,
    ['P'] = action.paste,
    ['S'] = action.change_sort,
    ['U'] = action.clear_selected_all,
    ['YY'] = action.yank_name,
  },
}
```

## Options

#### auto_cd
Change the working directory while navigating with vfiler.

- Type: `boolean`
- Default: `false`
- Command option format: `-auto-cd`

#### auto_resize
Enabled, it will automatically resize to the size specified by `width` and `height` options.

- Type: `boolean`
- Default: `false`
- Command option format: `-auto-resize`

#### columns
Specify the vfiler columns.<br>
see: [Column customization](##column-customization)

- Type: `string`
- Default: `indent,icon,name,mode,size,time`
- Command option format: `-columns={column1,column2,...}`

#### git.enabled
Handles Git information.

- Type: `boolean`
- Defalt: `true`
- Command option format: `-git-enabled`

#### git.ignored
Include Git ignored files.

- Type: `boolean`
- Defalt: `true`
- Command option format: `-git-ignored`

#### git.untracked
Include Git untracked files.

- Type: `boolean`
- Defalt: `true`
- Command option format: `-git-untracked`

#### header
Display the header line.

- Type: `boolean`
- Default: `true`
- Command option format: `-header`

#### keep
Keep the vfiler window with the open action.

- Type: `boolean`
- Default: `false`
- Command option format: `-keep`

#### listed
Display the vfiler buffer in the buffer list.

- Type: `boolean`
- Default: `true`
- Command option format: `-listed`

#### name
Specifies a buffer name. <br>

>NOTE: Buffer name must contain spaces.

- Type: `string`
- Default: `""`
- Command option format: `-name={buffer-name}`

#### new
Create new vfiler buffer.

- Type: `boolean`
- Default: `false`
- Command option format: `-new`

#### preview.layout
Specify the layout of the preview window.

- Layouts:
  - `left`: Split to the left.
  - `right`: Split to the right.
  - `top`: Split to the top.
  - `bottom`: Split to the bottom.
  - `floating`: Floating window.
- Type: `string`
- Defualt: `"floating"`
- Command option format: `-preview-layout={type}`

#### preview.height
The window height of the buffer whose layout is `top`, `bottom`, `floating`.<br>
If you specify `0`, the height will be calculated automatically.

- Type: `number`
- Default: `0`
- Command option format: `-prepreview-height={window-height}`

#### preview.width
The window width of the buffer whose layout is `left`, `right`, `floating`.<br>
If you specify `0`, the width will be calculated automatically.

- Type: `number`
- Default: `0`
- Command option format: `-preview-width={window-width}`

#### show_hidden_files
If enabled, Make hidden files visible by default.

- Type: `boolean`
- Default: `false`
- Command option format: `-show-hidden-files`

#### layout
Specify the layout of the window.

- Layouts:
  - `left`: Split to the left.
  - `right`: Split to the right.
  - `top`: Split to the top.
  - `bottom`: Split to the bottom.
  - `tab`: Create the new tabpage.
  - `floating`: Floating window.
  - `none`: No split or floating.
- Type: `string`
- Default: `"none"`
- Command option format: `-layout={type}`

#### height
Set the height of the window.<br>
It is a valid value when the window is splitted or floating by the `layout` option etc.

- Type: `number`
- Default: `0`
- Command option format: `-height={window-height}`

#### width
Set the width of the window.<br>
It is a valid value when the window is splitted or floating by the `layout` option etc.

- Type: `number`
- Default: `0`
- Command option format: `-width={window-width}`

#### row
Set the row position to display the floating window.<br>
If `0`, it will be set automatically according to the current window size.

> NOTE: This option is valid only when the `layout` option is `floating`.

- Type: `number`
- Default: `0`
- Command option format: `-row={window-row}`

#### col
Set the column position to display the floating window.<br>
If `0`, it will be set automatically according to the current window size.

> NOTE: This option is valid only when the `layout` option is `floating`.

- Type: `number`
- Default: `0`
- Command option format: `-col={window-column}`

#### blend
Enables pseudo-transparency for a floating window.<br>
Valid values are in the range of `0` for fully opaque window (disabled) to `100` for fully transparent background.<br>
Values between `0-30` are typically most useful.

> NOTE: This option is valid only when the `layout` option is `floating`.

- Type: `number`
- Default: `0`
- Command option format: `-blend={value}`

#### border
Style of window border.

> NOTE: This option is valid only when the `layout` option is `floating`.

- Type: `string`
- Default: `"rounded"`
- Command option format: `-border={type}`

#### zindex
Stacking order.<br>
floats with higher `zindex` go on top on floats with lower indices. <br>
Must be larger than zero.

> NOTE: This option is valid only when the `layout` option is `floating`.

- Type: `number`
- Default: `200`
- Command option format: `-zindex={value}`

## Mappings
vfiler also gives you the flexibility to customize your keymap.

### Change keymaps
If you don't like the default keymap, you can specify any key and the action for it in the mappings table.<br>
If there is no default keymap, it will be added.
```lua
local action = require('vfiler/action')
require('vfiler/config').setup {
  options = {
    -- Default configuration for vfiler goes here:
  },
  
  mappings = {
    -- Associate the action with the key mapping.
    -- Set the key string and action as a key-value pair.
    ['<C-h>'] = action.change_to_parent,
    ['<C-l>'] = action.open_tree,
    ['<C-c>'] = action.open_by_choose,
  },
}
```

### Unmap
You can remove the extra keymap.
```lua
-- Specify the key string you want to unmap. (e.g. '<CR>', 'h')
require'vfiler/config'.unmap(key)
```

### Clear keymaps
If you want to reassign the default keymap, you can delete all the default keymaps.
```lua
require'vfiler/config'.clear_mappings()
```
> NOTE: However, please call the function before specifying the keymap.

## Column customization
vfiler.vim supports several columns.  
You can change each column to show or hide, and also change the display order.

### How to specify.
List the column names separated by commas.<br>
The display order is from the left side of the description.

### Column types
| Name | Description |
| ---- | ---- |
| `name` | File name. |
| `indent` | Tree indentaion. |
| `icon` | Icon such as directory, and marks. |
| `mode` | File mode. |
| `size` | File size. |
| `time` | File modified time. |
| `type` | File type. |
| `git` | Git status. |
| `space` | Space column for padding. |

<!-- panvimdoc-ignore-start -->

### Example
#### Default
`columns = 'indent,icon,name,mode,size,time'`

![column-configurations-default](https://github.com/obaland/contents/blob/main/vfiler.vim/image-configurations-column-default.png?raw=true)

#### Reduce the columns
`columns = 'indent,name,size'`

![column-configurations-reduce](https://github.com/obaland/contents/blob/main/vfiler.vim/image-configurations-column-reduce.png?raw=true)

#### Change the order
`columns = 'indent,icon,name,time,mode,size'`

![column-configurations-order](https://github.com/obaland/contents/blob/main/vfiler.vim/image-configurations-column-order.png?raw=true)

<!-- panvimdoc-ignore-end -->

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
Toggle the ascending/descending order of the current sort method.

#### clear_selected_all
Clears marks in all lines.

#### switch_to_filer
Switch the filer buffer in the tab page. If there is no buffer to switch, create it.

> NOTE: It does not work in floating windows.

#### sync_with_current_filer
Synchronizes another filer current directory with current filer.

> NOTE: It does not work in floating windows.

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

# About

vfiler.vim is developed by obaland and licensed under the MIT License.<br>
Visit the project page for the latest information:

<https://github.com/obaland/vfiler.vim>

==============================================================================
