local helper = require('test.helper')
local feedkey = helper.feedkey
local mutchar = require('dynchar')
local ctx = require('dynchar.context')
local ns = vim.api.nvim_create_namespace('dynchar')
local eq = assert.equal

mutchar.setup({
  cpp = {
    [','] = { ' <!>', ctx.generic_in_cpp },
  },
  lua = {
    [';'] = { ':', ctx.semicolon_in_lua },
  },
  go = {
    [';'] = { ' := ', ctx.diagnostic_match({ 'undefine', 'expression' }) },
  },
  rust = {
    [';'] = {
      { '::', ctx.rust_double_colon },
      { ': ', ctx.rust_single_colon },
    },
    ['='] = { ' => ', ctx.rust_fat_arrow },
    ['-'] = { ' -> ', ctx.rust_thin_arrow },
  },
})

describe('mutchar', function()
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

  it('single variable define in go', function()
    vim.bo.filetype = 'go'
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'g' })
    vim.diagnostic.set(ns, bufnr, {
      {
        bufnr = bufnr,
        lnum = 0,
        end_lnum = 1,
        col = 1,
        end_col = 1,
        severity = 1,
        message = 'undefined a',
      },
    })
    feedkey(';')
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[1]
    eq('g := ', line)
  end)

  it('multiple variable define in go', function()
    vim.bo.filetype = 'go'
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'g,t' })
    vim.api.nvim_win_set_cursor(0, { 1, 3 })
    local ns = vim.api.nvim_create_namespace('mutchar')
    vim.diagnostic.set(ns, bufnr, {
      {
        bufnr = bufnr,
        lnum = 0,
        end_lnum = 1,
        col = 1,
        end_col = 1,
        severity = 1,
        message = 'expected 1 expression',
      },
    })
    feedkey(';')
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[1]
    eq('g,t := ', line)
  end)
end)
