# mutchar.nvim

a neovim plugin that change type character to other characters accroding rules and filter.

## Install

For lazy.nvim

```lua
require('lazy').setup(
    {'glepnir/mutchar.nvim', ft = {your configed filetypes in there},
    config = function()
        require('mutchar').setup({ config in there})
    end
    }
)
```

## Config

argument in `setup` function it's a table type that key is filetype value is table

```
{
    [filetype] = {
        rules      -- type is table,
        filter      -- type is function|table|nil
        one_to_one -- type is boolean only work when filter is table and  each element of
                      rules is table
    }
}
```
special character in rule `!`, this mean cursor in there. like your rule is `{',', '<!>'}` works for
generic. when you type `,` it will insert `<|>` and cursor in center of angle brackets.

`one_to_one` means each element in rules uses the filter with the same index in the filters table
like:

```lua
{
	["rust"] = {
		rules = {
			{ ";", ": " },
			{ "-", "->" },
			{ ",", "<!>" },
		},
		filter = {
			filters.semicolon_in_rust,
			filters.minus_in_rust,
			filters.generic_in_rust,
		},
		one_to_one = true,
	},
}
```

in this example that mean `rules[1]` will use `semicolon_in_rust`, `rules[2]` use the `minus_in_rust`
also you can set the mulitple filters for one rule like:

```lua
rules = {';', ': '}
filter = { filter_function1, filter_function2}

-- also with mulitple rules
rules = {
  {';', ': '},
}
filter = {
    {filter_function1, filter_function2},
}
```

## Filters

`filter` is `function|table|nil` each element is function. 

-  `filter` is nil it will do loop change in rules.
-  `filter` function have one param is `opt`, `opt` is a key value table key is `buf, lnum, col,`. 
-  `filter` is table. element can be filter function or table with element is filter function 

there has some default filters functions

```lua

local filters = require('mutchar.filters')

-- this function check the current col before has spae or not
filters.non_space_before(opt)

-- this function will check the diagnsotic message find the patterns or not
-- patterns is string or table
-- usage like `filters.find_diagnostic_msg({ "initial", "undeclare" })`
filters.find_diagnostic_msg(patterns)

-- works for cpp check current text is `tempalte` or not
filters.generic_in_cpp(opt)

-- works for `;` in rust file need treesitter
filters.semicolon_in_rust(opt)
-- works for '-' in rust file need treesitter
filters.minus_in_rust(opt)
-- works for `<>` in rust file need treesitter
filters.generic_in_rust(opt)

-- works for go file symbol <- need treesitter
filters.go_arrow_symbol(opt)
```

### Custome filter

you can custom filter function to determine whether the conditions for changing characters are met
and it return a boolean type

like:

```lua
local function custom_filter(opt)
  -- you can use opt.buf, opt.lnum (note the lnum is currentline - 1 so you can pass it to neovim
  -- api as well), opt.col
  if condition then
      -- true mean can change
      return true
  end
  return false
end
```

### Example usage

```lua
local filters = require('mutchar.filters')
require('mutchar').setup({
  ['c'] = {
    rules = { '-', '->' },
    filter = filters.non_space_before,
  },
  ['rust'] = {
    rules = {
      { ';', ': ' },
      { '-', '->' },
      { ',', '<!>' },
    },
    filter = {
      filters.semicolon_in_rust,
      filters.minus_in_rust,
      filters.generic_in_rust,
    },
    one_to_one = true,
  },
})
```

[My usage](https://github.com/glepnir/nvim/blob/main/lua/modules/editor/config.lua#L102)

## License MIT
