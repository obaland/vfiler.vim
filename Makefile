test-nvim:
	nvim --headless --noplugin -u tests/init.vim -c "PlenaryBustedDirectory tests/vfiler { minimal_init = './tests/init.vim' }"

lint:
	luacheck lua
