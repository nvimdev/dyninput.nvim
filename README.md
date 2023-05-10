# MutChar.nvim

change the input character according the context need neovim 0.10+

## Install

- Lazy.nvim

```lua
require('lazy').setup({
    'nvimdev/mutchar.nvim',
    config = function()
        require('mutchar').setup(conf)
    end,
})
```

## Config

rule in setup config table. example config

```lua
local ctx = require('mutchar.context')
require('mutchar').setup({
  go = {
    [';'] =  {':= ', ctx.diagnostic_match({'undefine','expression'}) },
  },
  cpp = {
    [','] = { ' <!>', ctx.generic_in_cpp },
    ['-'] = { '->', ctx.non_space_before },
  },
})
```

## Default Context Provider

```
ctx.non_space_before -- check before has space or not
ctx.generic_in_cpp   -- generic symbol in cpp
ctx.diagnsotic_match -- string|table when diagnostic match pattern
ctx.rust_ret_arrow   -- -> function return type
```

write your own context filter . write a function and it will have a param `opt`
in `opt`  it has fields `buf, lnum, col`, lnum is 1 basic in neovim api line always 0 basic. so you
may need lnum - 1 in neovim api

```
local function custom_ctx_filter(opt)
end
```
