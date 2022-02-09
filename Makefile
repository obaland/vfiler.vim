test:
	nvim --headless --noplugin -u scripts/init.vim -c "PlenaryBustedDirectory tests/vfiler { minimal_init = './scripts/init.vim' }"

lint:
	luacheck lua

doc:
	nvim --headless --noplugin -u scripts/init.vim -c "luafile ./scripts/gendocs.lua" -c 'qa'
