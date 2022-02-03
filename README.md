[![CI](https://github.com/obaland/vfiler.vim/workflows/ci-neovim/badge.svg)](https://github.com/obaland/vfiler.vim/actions?query=workflow%3Aci-neovim)
[![Lint](https://github.com/obaland/vfiler.vim/workflows/lint/badge.svg)](https://github.com/obaland/vfiler.vim/actions?query=workflow%3Alint)

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

Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'obaland/vfiler.vim'
```

Using [dein.vim](https://github.com/Shougo/dein.vim)

```vim
call dein#add('obaland/vfiler.vim')
```
## Usage
### Quick Start
Basically, after installing in any way, start with the **VFiler** command.

    :VFiler

The vfiler will start in the current directory.

### Start by calling a Lua function
vfiler can also be started by calling a `require'vfiler'.start()`.
```lua
require('vfiler').start(path)
```

### More details
Checkout wiki for more details:
- [Usage details](https://github.com/obaland/vfiler.vim/wiki/usage-details)


## Customization
vfiler can be customized to your liking.<br>
The following is an example.

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

### More details
vfiler has various other customization mechanisms.<br>
Checkout wiki for more details:
- [Customization](https://github.com/obaland/vfiler.vim/wiki/Customization)

## Extension plugins
There are also some extension plugins for vfiler.<br>
Please use it as you like.
- [obaland/vfiler-column-devicons](https://github.com/obaland/vfiler-column-devicons)
- [obaland/vfiler-fzf](https://github.com/obaland/vfiler-fzf)

## Screenshots
### Basic (with [devicons](https://github.com/obaland/vfiler-column-devicons))
![basic](https://github.com/obaland/contents/blob/main/vfiler.vim/image-basic.png?raw=true)

### Operation with two buffers
![multiple](https://github.com/obaland/contents/blob/main/vfiler.vim/image-multiple.png?raw=true)

### Explorer style (with [devicons](https://github.com/obaland/vfiler-column-devicons))
![tree](https://github.com/obaland/contents/blob/main/vfiler.vim/image-tree.png?raw=true)

## Feedback
I am hoping to continually improve it as far as time permits.<br>
Welcome your requests and suggestions, so please [create an issue](https://github.com/obaland/vfiler.vim/issues/new).

## License
Paddington is licensed under the MIT license.
Copyright © 2018, obaland
