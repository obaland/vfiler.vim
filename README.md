<p align="center">
  <img src="https://github.com/obaland/contents/blob/main/vfiler.vim/logo.png?raw=true" alt="vfiler-logo" width=75% height=auto>
</p>

# File explorer plugin for Neovim/Vim

[![CI](https://github.com/obaland/vfiler.vim/actions/workflows/ci.yml/badge.svg)](https://github.com/obaland/vfiler.vim/actions/workflows/ci.yml)
[![Lint](https://github.com/obaland/vfiler.vim/actions/workflows/lint.yml/badge.svg)](https://github.com/obaland/vfiler.vim/actions/workflows/lint.yml)

## Description

- :page_facing_up: Performing basic file operations.
- :bookmark_tabs: Supports easy-to-use 2-window filer.
- :sparkle: Light operability.
- :customs: Customizable to your liking.
- :link: Not depends on other plugins or external.

![demo](https://github.com/obaland/contents/blob/main/vfiler.vim/image-demo.gif?raw=true)

## Requirements

vfiler.vim requires Neovim(0.8.0+) or Vim8.2+ with [if\_lua](https://vimhelp.org/if_lua.txt.html#if_lua.txt).

## Installation

Using [vim-plug](https://github.com/junegunn/vim-plug)
```vim
Plug 'obaland/vfiler.vim'
```

Using [dein.vim](https://github.com/Shougo/dein.vim)
```vim
call dein#add('obaland/vfiler.vim')
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use {
  'obaland/vfiler.vim',
}
```

## Usage
### Quick Start
Basically, after installing in any way, start with the `VFiler` command. The vfiler.vim will start in the current directory.

    :VFiler

You can do various things with `options`.<br>
See [command usage](https://github.com/obaland/vfiler.vim/blob/main/doc/vfiler.md#command-usage) for details.

### Start by Lua function
vfiler.vim can also be started by calling a `require'vfiler'.start()`.
```lua
require('vfiler').start({path})
```
You can do various things with `configs`.<br>
See [Lua function usage](https://github.com/obaland/vfiler.vim/blob/main/doc/vfiler.md#lua-function-usage) for details.

### More details
- Please see more details: [Usage](https://github.com/obaland/vfiler.vim/blob/main/doc/vfiler.md#usage)


## Customization
vfiler.vim can be customized to your liking.<br>
The following is an example.

### Explorer style
#### Start by command:
```vim
:VFiler -auto-cd -auto-resize -keep -layout=left -name=explorer -width=30 -columns=indent,icon,name
```

#### Start by Lua script:
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

### More details
vfiler.vim has various other customization mechanisms.<br>
- Please see more details: [Customization](https://github.com/obaland/vfiler.vim/blob/main/doc/vfiler.md#customization)

## Extension plugins
There are also some extension plugins for vfiler.vim.<br>
Please use it as you like.
- [obaland/vfiler-column-devicons](https://github.com/obaland/vfiler-column-devicons)
- [obaland/vfiler-fzf](https://github.com/obaland/vfiler-fzf)
- [obaland/vfiler-action-yanktree](https://github.com/obaland/vfiler-action-yanktree)

## Screenshots
### Basic (with [devicons](https://github.com/obaland/vfiler-column-devicons))
![basic](https://github.com/obaland/contents/blob/main/vfiler.vim/image-basic.png?raw=true)

### Operation with two buffers
![multiple](https://github.com/obaland/contents/blob/main/vfiler.vim/image-multiple.png?raw=true)

### Explorer style (with [devicons](https://github.com/obaland/vfiler-column-devicons))
![tree](https://github.com/obaland/contents/blob/main/vfiler.vim/image-tree.png?raw=true)

### Floating window style (only Neovim)
![tree](https://github.com/obaland/contents/blob/main/vfiler.vim/image-floating.png?raw=true)

## Feedback
I am hoping to continually improve it as far as time permits.<br>
Welcome your requests and suggestions, so please [create an issue](https://github.com/obaland/vfiler.vim/issues/new).

## License
`vfiler.vim` is licensed under the MIT license.<br>
Copyright © 2018, obaland
