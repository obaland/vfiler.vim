<p align="center">
  <img src="https://github.com/obaland/contents/blob/main/vfiler.vim/logo.png?raw=true" alt="vfiler-logo" width=75% height=auto>
</p>

# File explorer plugin for Vim/Neovim

## Description

- **File manager**

  You can perform basic operations such as selecting, creating, deleting,
  copying, moving, and renaming files.

- **Operation between multiple buffers**

  It can be treated as 2 window filer. This makes file operations easier to
  handle.

- **Not depends on other plugins.**

  It works independently without relying on other plugins.

- **Required enough feature, lightweight operation**

  Aiming for the necessary and sufficient functions to increase working
  efficiency and their lightweight operation.

![demo](https://github.com/obaland/contents/blob/main/vfiler.vim/image-demo.png?raw=true)

## Requirements

vfiler.vim requires Neovim(0.5.0+) or Vim8.2+ with [if\_lua](https://vimhelp.org/if_lua.txt.html#if_lua.txt).

## Instalattion

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'obaland/vfiler.vim'
```

### Using [dein.vim](https://github.com/Shougo/dein.vim)

```vim
call dein#add('obaland/vfiler.vim')
```
## Usage
### Quick Start
Basically, after installing in any way, start with the **VFiler** command.

    :VFiler [{options}...] [{path}]

If {path} is not specified, it will start in the current directory.
{options} are options for a filer buffer.
Please see the [documentation][vim-doc] for details.

### Start by calling a lua function
vfiler can also be started by calling a lua function.
```lua
require('vfiler').start(path)
```

## Configuration
### Explorer style
#### Starting with a command:
```vim
:VFiler -auto-cd -auto-resize -keep -layout=left -name=explorer -width=30 columns=indent,icon,name
```

#### Starting with a lua script:
```lua
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

### Default settings
```lua
local action = require('vfiler/action')
require('vfiler/config').setup {
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
    statusline = true,
    layout = 'none',
    width = 90,
    height = 30,
    new = false,
    quit = true,
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
    ['<S-Space>'] = action.toggle_select_up,
    ['<Space>'] = action.toggle_select_down,
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

## Extension plugins
- [obaland/vfiler-column-devicons](https://github.com/obaland/vfiler-column-devicons)
- [obaland/vfiler-fzf](https://github.com/obaland/vfiler-fzf)

## Screenshots
### Basic
![basic](https://github.com/obaland/contents/blob/main/vfiler.vim/image-basic.png?raw=true)

### Operation with two buffers
![multiple](https://github.com/obaland/contents/blob/main/vfiler.vim/image-multiple.png?raw=true)

### Explorer style
![tree](https://github.com/obaland/contents/blob/main/vfiler.vim/image-tree.png?raw=true)

### Extension by [devicons](https://github.com/obaland/vfiler-column-devicons)
![devicons](https://github.com/obaland/contents/blob/main/vfiler.vim/image-devicons.png?raw=true)

## Lastly
I am hoping to continually improve it as far as time permits,  
so I'd appreciate it if you can receive various opinions including differences within the script.

## License
Paddington is licensed under the MIT license.
Copyright © 2018, obaland

[vim-doc]: https://github.com/obaland/vfiler.vim/blob/main/doc/vfiler.txt
