test-nvim:
	nvim --headless --noplugin -u tests/init.vim -c "BustedDirectory tests/vfiler { init = './tests/init.vim' }"

test-vim:
	vim -u tests/init.vim -i NONE -n -e -s -c "BustedDirectory tests/vfiler { init = './tests/init.vim' }"

lint:
	luacheck lua
