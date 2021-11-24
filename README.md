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

## Requirements

vfiler.vim requires Neovim(0.5.0+) or Vim8.2 + with [if\_lua](http://vimdoc.sourceforge.net/htmldoc/if_lua.html).

## Instalattion

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'obaland/vfiler.vim'
```

### Using [dein.vim](https://github.com/Shougo/dein.vim)

```vim
call dein#add('obaland/vfiler.vim')
```

## Demo
### Basic
![basic](https://github.com/obaland/contents/blob/main/vfiler.vim/image-basic.png?raw=true)

### Operation with two buffers
![multiple](https://github.com/obaland/contents/blob/main/vfiler.vim/image-multiple.png?raw=true)

### Explorer style
![tree](https://github.com/obaland/contents/blob/main/vfiler.vim/image-tree.png?raw=true)

## Quick Start
Basically, after installing in any way, start with the **VFiler** command.

    :VFiler [{path}]

If {path} is not specified, it will start in the current directory.

Please see the [documentation][vim-doc] for details.

## Configuration
### Explorer style

```vim
function VFilerForExplorer()
lua<<EOF
  local action = require'vfiler/action'
  require'vfiler/config'.setup {
    options = {
      auto_cd = true,
      name = 'explorer',
      direction = 'left',
      width = 30,
      columns = 'indent,icon,name',
    },

    mappings = {
      -- Change open action
      ['<CR>']  = action.open_by_choose_or_cd,

      -- Disable switch to filer
      ['<Tab>'] = nil,
    },
  }

  local path = vim.fn.getcwd()
  require'vfiler'.start(path)
EOF
endfunction

command! -nargs=0 VFilerExplorer call VFilerForExplorer()
```

## Finally
I am hoping to continually improve it as far as time permits,  
so I'd appreciate it if you can receive various opinions including differences within the script.

## License
Paddington is licensed under the MIT license.  
Copyright © 2018, obaland

[vim-doc]: https://github.com/obaland/vfiler.vim/blob/master/doc/vfiler.txt
