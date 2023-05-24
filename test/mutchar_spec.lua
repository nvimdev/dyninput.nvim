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
      { ': ', ctx.rust_single_colon },
    },
    ['='] = { ' => ', ctx.rust_fat_arrow },
    ['-'] = { ' -> ', ctx.rust_thin_arrow },
  },
})

local t = function(s)
  return vim.api.nvim_replace_termcodes(s, true, true, true)
end

local feedkey = function(key)
  vim.api.nvim_feedkeys(t('a' .. key), 'x', false)
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
  local parser_dir = join_paths(treesitter_path, 'parser')
  require('nvim-treesitter').setup({
    ensure_installed = { 'rust' },
    sync_install = true,
    highlight = { enable = true },
    parser_install_dir = parser_dir,
  })
  if vim.fn.filereadable(join_paths(parser_dir, 'rust.so')) == 0 then
    vim.cmd('TSInstallSync rust')
  end
end

describe('mutchar', function()
  treesitter_dep()
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

  -- there need test with treesitter
  describe('in rust with rust_double_colon', function()
    it('after String keyword', function()
      vim.bo.filetype = 'rust'
      vim.treesitter.start(bufnr, 'rust')
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'fn main () {', '    let s = String', '}' })
      vim.api.nvim_win_set_cursor(0, { 2, 18 })
      feedkey(';')
      local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[2]
      eq('    let s = String::', line)
    end)

    it('after module', function()
      vim.bo.filetype = 'rust'
      vim.api.nvim_buf_set_lines(
        bufnr,
        0,
        -1,
        false,
        { 'mod module;', 'fn main(){', '    module', '}' }
      )
      vim.cmd('TSBufEnable highlight')
      vim.api.nvim_win_set_cursor(0, { 3, 9 })
      feedkey(';')
      local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[3]
      eq('    module::', line)
    end)

    it('after std use', function()
      vim.bo.filetype = 'rust'
      vim.api.nvim_buf_set_lines(
        bufnr,
        0,
        -1,
        false,
        { 'use std::io;', 'fn main(){', '    io', '}' }
      )
      vim.treesitter.start(bufnr, 'rust')
      vim.treesitter.query.set(
        'rust',
        'highlights',
        [[
        (use_declaration
          (scoped_identifier
            name: (identifier) @namespace))
      ]]
      )
      vim.api.nvim_win_set_cursor(0, { 3, 9 })
      feedkey(';')
      local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[3]
      eq('    io::', line)
    end)

    it('rust_single_colon', function()
      vim.bo.filetype = 'rust'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
        'enum Direction {',
        '    Up,',
        '    Down,',
        '}',
        'pub fn main() {',
        '    let test = Direction::Up',
        '}',
      })
      vim.api.nvim_win_set_cursor(0, { 6, 28 })
      feedkey(';')
      local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[6]
      eq('    let test = Direction::Up;', line)
    end)

    it('in struct with diagnsotic', function()
      vim.bo.filetype = 'rust'
      vim.treesitter.start(bufnr, 'rust')
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
      feedkey(';')
      local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[2]
      eq('    username: ', line)
    end)

    it('rust match arrow symbol', function()
      vim.bo.filetype = 'rust'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
        'enum Direction {',
        '    Up,',
        '    Down,',
        '}',
        'pub fn main() {',
        '    let test = Direction::Up;',
        '    match test {',
        '        Direction::Up',
        '    }',
        '}',
      })
      vim.treesitter.start(bufnr, 'rust')
      vim.api.nvim_win_set_cursor(0, { 8, 20 })
      feedkey('=')
      local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[8]
      eq('        Direction::Up => ', line)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false , {
        'use std::io::File;',
        'fn main() {',
        '    let f = File::open("test.rs");',
        '    let file = match f {',
        '        Ok(fd)',
        '    }',
        '}',
      })
      vim.treesitter.start(bufnr, 'rust')
      vim.api.nvim_win_set_cursor(0, {5, 13})
      feedkey('=')
      line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[5]
      eq('        Ok(fd) => ', line)
    end)

    it('rust thin arrow', function()
      vim.bo.filetype = 'rust'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
        'fn test()',
      })
      vim.api.nvim_win_set_cursor(0, { 1, 9 })
      feedkey('-')
      local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[1]
      eq('fn test() -> ', line)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
        'pub fn test()',
      })
      vim.api.nvim_win_set_cursor(0, { 1, 13 })
      feedkey('-')
      line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[1]
      eq('pub fn test() -> ', line)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
        'fn main() {',
        '    fn inline()',
        '}',
      })
      vim.api.nvim_win_set_cursor(0, { 2, 16 })
      feedkey('-')
      line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[2]
      eq('    fn inline() -> ', line)
    end)
  end)
end)
