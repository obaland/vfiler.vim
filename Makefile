test:
	nvim --headless --noplugin -u NONE -i NONE -n \
		-c "luafile tests/run.lua" -c "cquit 1"

lint:
	luacheck lua

doc:
	pandoc \
		--metadata=project:vfiler.vim \
		--metadata=description:"File manager plugin for Vim/Neovim" \
		--lua-filter ../panvimdoc/scripts/skip-blocks.lua \
		--lua-filter ../panvimdoc/scripts/include-files.lua \
		-t ../panvimdoc/scripts/panvimdoc.lua \
		./doc/vfiler.md -o ./doc/vfiler.txt
