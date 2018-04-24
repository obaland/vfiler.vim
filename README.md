# vfiler.vim
vfiler is a file manager written in Vim script.

## Concept
- **File manager**

  You can perform basic operations such as selecting, creating, deleting,
  copying, moving, and renaming files.

- **Operation between multiple buffers**

  It can be treated as 2 window filer. This makes file operations easier to
  handle.

- **Explorer mode**

  It supports Explorer mode like "netrw" or modern IDE environment.

- **Not depends on other plugins.**

  It works independently without relying on other plugins.

- **Required enough feature, lightweight operation**

  Aiming for the necessary and sufficient functions to increase working
  efficiency and their lightweight operation.

## Demo
### Basic
----------------------------
![VFiler basic operations](https://user-images.githubusercontent.com/36218691/39186047-2cdc472e-4804-11e8-8b2c-dc8575dc4832.gif)

### Operation with two buffers
----------------------------
![VFiler operations with two buffers](https://user-images.githubusercontent.com/36218691/39186056-304d7b6c-4804-11e8-947e-9e025750d594.gif)

### Explorer mode
----------------------------
![VFiler explorer mode](https://user-images.githubusercontent.com/36218691/39186060-32a38014-4804-11e8-8ab0-67e3d3637b22.gif)

## Usage
Basically, after installing in any way, start with the **VFiler** command.

    :VFiler [{path}]

Please see the [documentation][vim-doc] for details.

## Special Thanks
When implementing this plug-in, I referred to the following excellent program and software.  
I would like to express my special appreciation.  
In implementing this plugins, I referred to the following products.

* [vimfiler](https://github.com/Shougo/vimfiler.vim)

* [vaffle](https://github.com/cocopon/vaffle.vim)

* [netrw](https://github.com/vim-scripts/netrw.vim)

* [xyzzy (filer)](https://github.com/xyzzy-022/xyzzy)

## Finally
I am hoping to continually improve it as far as time permits,  
so I'd appreciate it if you can receive various opinions including differences within the script.

## License
Paddington is licensed under the MIT license.  
Copyright © 2018, obaland

[vim-doc]: https://github.com/obaland/vfiler.vim/blob/master/doc/vfiler.txt
