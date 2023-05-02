local ctx = require('mutchar.context')
require('mutchar').setup({
  cpp = {
    [','] = { ' <!>', ctx.generic_in_cpp },
    ['-'] = { '->', ctx.non_space_before },
  },
})
