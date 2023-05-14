local mutchar = require('mutchar')
local ctx = require('mutchar.context')
local ns = vim.api.nvim_create_namespace('mutchar')
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
      { ':', ctx.diagnostic_match('expected COLON') },
    },
  },
})

local t = function(s)
  return vim.api.nvim_replace_termcodes(s, true, true, true)
end

local function join_paths(...)
  local path_sep = on_windows and '\\' or '/'
  local result = table.concat({ ... }, path_sep)
  return result
end

local function treesitter_dep()
  local data_path = vim.fn.stdpath('data')

  local package_root = join_paths(data_path, 'test')
  local treesitter_path = join_paths(package_root, 'nvim-treesitter')
  vim.opt.runtimepath:append(treesitter_path)

  if vim.fn.isdirectory(treesitter_path) ~= 1 then
    vim.fn.system({
      'git',
      'clone',
      'https://github.com/nvim-treesitter/nvim-treesitter',
      treesitter_path,
    })
  end
  require('nvim-treesitter').setup({
    ensure_installed = { 'rust' },
    sync_install = true,
    highlight = { enable = true },
  })
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
    eq('template <>', line)
  end)

  it('semicolon in lua', function()
    vim.bo.filetype = 'lua'
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'function self' })
    vim.api.nvim_win_set_cursor(0, { 1, 13 })
    vim.api.nvim_feedkeys(t('a;'), 'x', false)
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
    vim.api.nvim_feedkeys(t('a;'), 'x', false)
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
    vim.api.nvim_feedkeys(t('a;'), 'x', false)
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[1]
    eq('g,t := ', line)
  end)

  -- there need test with treesitter
  describe('in rust with rust_double_colon', function()
    it('after String keyword', function()
      vim.bo.filetype = 'rust'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'fn main () {', '    let s = String', '}' })
      vim.api.nvim_win_set_cursor(0, { 2, 18 })
      vim.api.nvim_feedkeys(t('a;'), 'x', false)
      local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[2]
      eq('    let s = String::', line)
    end)

    it('in struct with diagnsotic', function()
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
      eq('    username:', line)
    end)
  end)
end)
