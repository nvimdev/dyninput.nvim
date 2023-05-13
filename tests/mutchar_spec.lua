local mutchar = require('mutchar')
local ctx = require('mutchar.context')
local ns = vim.api.nvim_create_namespace('mutchar')

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
      { ':', ctx.diagnostic_match('expected COLON') },
    },
  },
})

local t = function(s)
  return vim.api.nvim_replace_termcodes(s, true, true, true)
end

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
    vim.api.nvim_feedkeys(t('a,'), 'x', false)
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[1]
    assert.equal('template <>', line)
  end)

  it('semicolon in lua', function()
    vim.bo.filetype = 'lua'
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'function self' })
    vim.api.nvim_win_set_cursor(0, { 1, 13 })
    vim.api.nvim_feedkeys(t('a;'), 'x', false)
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[1]
    assert.equal('function self:', line)
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
    vim.api.nvim_feedkeys(t('a;'), 'x', false)
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[1]
    assert.equal('g := ', line)
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
    vim.api.nvim_feedkeys(t('a;'), 'x', false)
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[1]
    assert.equal('g,t := ', line)
  end)

  it('rust double colon', function()
    vim.bo.filetype = 'rust'
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'fn main () {', '    let s = String', '}' })
    vim.api.nvim_win_set_cursor(0, { 2, 18 })
    vim.api.nvim_feedkeys(t('a;'), 'x', false)
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[2]
    assert.equal('    let s = String::', line)
  end)

  it('rust colon in struct', function()
    vim.bo.filetype = 'rust'
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'struct Test {', '    username', '}' })
    vim.api.nvim_win_set_cursor(0, { 2, 11 })
    vim.diagnostic.set(ns, bufnr, {
      {
        bufnr = bufnr,
        lnum = 1,
        end_lnum = 2,
        col = 12,
        end_col = 12,
        severity = 1,
        message = 'expected COLON',
      },
    })
    vim.api.nvim_feedkeys(t('a;'), 'x', false)
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[2]
    assert.equal('    username:', line)
  end)
end)
