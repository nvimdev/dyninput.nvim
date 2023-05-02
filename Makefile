nvim ?= nvim

test:
	$(nvim) --headless --clean --noplugin -c 'set rtp+=~/Workspace/plenary.nvim' -c 'packadd plenary.nvim' -c "PlenaryBustedDirectory ./tests/ { minimal_init = 'tests/minimal_init.lua' }"

.PHONY: test
