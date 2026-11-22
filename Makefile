VIM_BIN ?= vim

.PHONY: test test-nvim test-vim

test:
	@status=0; \
	$(MAKE) test-nvim || status=1; \
	$(MAKE) test-vim || status=1; \
	exit $$status

test-nvim:
	nvim --headless --noplugin -u NONE -i NONE -n \
		-c "luafile tests/run.lua" -c "cquit 1"

test-vim:
	$(VIM_BIN) -Nu NONE -i NONE -n -es -V1 -S tests/run-vim.vim -c "cquit 1"

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
