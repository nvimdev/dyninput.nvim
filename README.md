# dynchar.nvim

Dynamisc change the type character according the context need neovim 0.10+

Note: In develope may breakchange any time

## Install

must neovim 0.10+(head) version

- Lazy.nvim

```lua
require('lazy').setup({
    'nvimdev/dynchar.nvim',
    config = function()
        require('dynchar').setup(conf)
    end,
})
```

## Config

rule in setup config table. example config

```lua
local ctx = require('dynchar.context')
require('dynchar').setup({
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
