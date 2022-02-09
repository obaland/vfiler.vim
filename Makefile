test:
	nvim --headless --noplugin -u tests/init.vim \
		-c "PlenaryBustedDirectory tests/vfiler { minimal_init = './tests/init.vim' }"

lint:
	luacheck lua

doc:
	pandoc \
		--metadata=project:vfiler.vim \
		--metadata=description:"File manager plugin for Vim/Neovim" \
		--lua-filter ../panvimdoc/scripts/skip-blocks.lua \
		--lua-filter ../panvimdoc/scripts/include-files.lua \
		-t ../panvimdoc/scripts/panvimdoc.lua \
		./doc/vfiler.md -o ./doc/vfiler_.txt
