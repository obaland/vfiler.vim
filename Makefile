test:
	nvim --headless --noplugin -u tests/init.vim -c "BustedDirectory tests/vfiler"

lint:
	luacheck lua
