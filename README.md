# dyninput.nvim

Fucking Shift!!
Dynamisc change the input according the context need neovim 0.10+

![Untitled](https://github.com/nvimdev/dyninput.nvim/assets/41671631/96402303-f9eb-4485-81a1-843b9dc33605)

input `\` it give me `||{}` and cursor between `|`. shift? you don't need then.

## Install

must neovim 0.10+(head) version

- Lazy.nvim

```lua
require('lazy').setup({
    'nvimdev/dyninput.nvim',
    config = function()
        require('dyninput').setup(conf)
    end,
    dependencies = {'nvim-treesitter/nvim-treesitter'}
})
```

## SetUp

rule in setup config table. example config

```lua
local rs = require('dyninput.lang.rust')
local ms = require('dyninput.lang.misc')
require('dyninput').setup({
  c = {
    ['-'] = {
      { '->', ms.c_struct_pointer },
      { '_', ms.snake_case },
    },
  },
  rust = {
    [';'] = {
      { '::', rs.double_colon },
      { ': ', rs.single_colon },
    },
    ['='] = { ' => ', rs.fat_arrow },
    ['-'] = {
      { ' -> ', rs.thin_arrow },
      { '_', ms.snake_case },
    },
    ['\\'] = { '|!| {}', rs.closure_fn },
  },
})
```

in setup param table key is filetype and value is table with key and rules.
```
ft = {
    [rule key] = rule -- table | List-like table
}
```
specail of `!` thise mean cursor in there

## Custom

rule is a table first element must be new character(s) which will insert to buffer.
secound element is a filter function that receive a param `opt` a table type param
`opt` has `{buf,lnum,col}` field. when filter function return true mean this rule need
take effect.

there has some default context filter of language `dyninput.misc` and `dyninput.rust`

- List of some languages implment in default.

```lua
local ms = require('dyninput.lang.misc')
ms.c_struct_pointer  -- match struct pointer variable usually use for arrow symbol `&strcut->field`
ms.generic_in_cpp    -- match before word of cursor is template
ms.snake_case        -- match snake_case
ms.semicolon_in_lua  -- match before word is self or is a variable
ms.go_variable_define-- match the situation of variable define like `g :=` `g,x :=`
ms.go_struct_field   -- match word in struct `struct { name:--here }`
```

- For Rust

```lua
local rs = require('dyninput.lang.rust')
rs.double_colon      -- match double colon
rs.single_colon      -- match single colon
rs.fat_arrow         -- match in `match` expression
rs.thin_arrow        -- match is function return
rs.closure_fn        -- match closure
```

### Write Own Context filter

you can according naming conventions, (AST)tresitter node type or lsp symbols or
highlights or other the way that can detect which is the new characters need input.
in `dyninput.util` there has some useful functions wrap can used. more detail can look at `util` module.

```
---opt table
---lnum is 1 indexed when you use some apis of neovim which need row (0 indexed) you need lnum -1
function my_own(opt)
    print(opt.lnum, opt.col, opt.buf)
    return ture
end
```

then use your own context filter

```
require('dyninput').setup({
    your_language = {
        ['character'] = { 'new characters', my_own }
    }
})
```

More usage you can reference [my config](https://github.com/glepnir/nvim/blob/main/lua/modules/tools/config.lua#L35)

## Contribute

Thanks for contribute this plugin. most case need write a test for your patch. How to run test in
local. `vusted` command is required, `vusted test` under `dyninput.nvim` dir

```
luarocks --lua-version=5.1 install vusted
```

For some dependcies like treesitter. you can use `DYNTEST` env variable to define a path in your
local like `DYNTEST=/path/to/nvim-treesitter vusted test`.

## License MIT
