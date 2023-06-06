local helper = require('test.helper')
local feedkey = helper.feedkey
local ns = vim.api.nvim_create_namespace('dyninput')
local eq = assert.equal

local rs = require('dyninput.lang.rust')
local ms = require('dyninput.lang.misc')
require('dyninput').setup({
  c = {
    ['-'] = { '->', ms.c_struct_pointer },
  },
  cpp = {
    [','] = { ' <!>', ms.generic_in_cpp },
    ['-'] = { '->', ms.c_struct_pointer },
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
  lua = {
    [';'] = { ':', ms.semicolon_in_lua },
  },
  go = {
    [';'] = {
      { ' := ', ms.go_variable_define },
      { ': ', ms.go_struct_field },
    },
  },
})

describe('dyninput should work as expect', function()
  helper.treesitter_dep()
  local bufnr
  before_each(function()
    bufnr = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_win_set_buf(0, bufnr)
  end)

  it('generic in cpp after template keyword', function()
    vim.bo[bufnr].filetype = 'cpp'
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'template' })
    vim.api.nvim_win_set_cursor(0, { 1, 8 })
    feedkey(',')
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[1]
    eq('template <>', line)
  end)

  it('semicolon in lua', function()
    vim.bo.filetype = 'lua'
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'function self' })
    vim.api.nvim_win_set_cursor(0, { 1, 13 })
    feedkey(';')
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[1]
    eq('function self:', line)
  end)

  it('go test', function()
    vim.bo.filetype = 'go'
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      'func main() {',
      '    g',
      '}',
    })
    vim.api.nvim_win_set_cursor(0, { 2, 5 })
    vim.cmd('TSBufEnable highlight')
    feedkey(';')
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[2]
    eq('    g := ', line)
  end)

  it('go mulitple variable define', function()
    vim.bo[bufnr].filetype = 'go'
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      'func main() {',
      '    a,b',
      '}',
    })
    vim.cmd('TSBufEnable highlight')
    vim.api.nvim_win_set_cursor(0, { 2, 6 })
    feedkey(';')
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[2]
    eq('    a,b := ', line)
  end)

  it('go strcut field', function()
    vim.bo[bufnr].filetype = 'go'
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      'type Person struct {',
      '    name string',
      '}',
      'func main() {',
      '    t := Person {',
      '        name',
      '    }',
      '}',
    })
    vim.cmd('TSBufEnable highlight')
    vim.api.nvim_win_set_cursor(0, { 6, 12 })
    feedkey(';')
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[6]
    eq('        name: ', line)
  end)
end)
