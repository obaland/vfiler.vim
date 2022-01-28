test:
	nvim --headless --noplugin -u tests/minimal_init.vim -c "PlenaryBustedDirectory tests"

lint:
	luacheck lua
