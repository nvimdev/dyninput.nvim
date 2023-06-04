local helper = require('test.helper')
local feedkey = helper.feedkey
local eq = assert.equal

-- there need test with treesitter
describe('rust file', function()
  helper.treesitter_dep()
  local bufnr
  before_each(function()
    bufnr = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_win_set_buf(0, bufnr)
  end)

  it('double colon', function()
    vim.bo.filetype = 'rust'
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'fn main () {', '    let s = String', '}' })
    vim.api.nvim_win_set_cursor(0, { 2, 18 })
    vim.cmd('TSBufEnable highlight')
    feedkey(';')
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[2]
    eq('    let s = String::', line)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      'fn main(){',
      '    let s = (String)',
      '}',
    })
    vim.api.nvim_win_set_cursor(0, { 2, 18 })
    feedkey(';')
    line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[2]
    eq('    let s = (String::)', line)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      'fn main(){',
      '    let v = Vec',
      '}',
    })
    vim.api.nvim_win_set_cursor(0, { 2, 14 })
    vim.cmd('TSBufEnable highlight')
    feedkey(';')
    line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[2]
    eq('    let v = Vec::', line)
  end)

  it('double colon after generic', function()
    vim.bo[bufnr].filetype = 'rust'
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      'use std::collections::HashMap',
      'fn main(){',
      '    let v = HashMap::<i32, i32>',
      '}',
    })
    vim.cmd('TSBufEnable highlight')
    vim.api.nvim_win_set_cursor(0, { 3, 32 })
    feedkey(';')
    line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[3]
    eq('    let v = HashMap::<i32, i32>::', line)
  end)

  it('double colon after module', function()
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

  it('double colon after use namespace', function()
    vim.bo.filetype = 'rust'
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'use std::io;', 'fn main(){', '    io', '}' })
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
    vim.treesitter.query.set(
      'rust',
      'highlights',
      [[
        (use_declaration
            (identifier) @namespace)
      ]]
    )
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      'use rand;',
      'fn main(){',
      '    rand',
      '}',
    })
    vim.cmd('TSBufEnable highlight')
    vim.api.nvim_win_set_cursor(0, { 3, 8 })
    feedkey(';')
    line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[3]
    eq('    rand::', line)
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
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'use std::io' })
    vim.api.nvim_win_set_cursor(0, { 1, 10 })
    feedkey(';')
    line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[1]
    eq('use std::io;', line)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      'ust std::fmt::Display',
      'fn longest<T, U>(x: T, y:U) -> T',
      'where T',
    })
    vim.cmd('TSBufEnable highlight')
    vim.api.nvim_win_set_cursor(0, { 3, 7 })
    feedkey(';Display, U;Display')
    line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[3]
    eq('where T: Display, U: Display', line)
  end)

  it('after mut keyword in parameters', function()
    vim.bo[bufnr].filetype = 'rust'
    vim.api.nvim_buf_set_lines(bufnr,0,-1, false, {
      'pub fn test(mut args) {}'
    })
    vim.cmd('TSBufEnable highlight')
    vim.api.nvim_win_set_cursor(0, { 1, 19 })
    feedkey(';')
    line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[1]
    eq('pub fn test(mut args: ) {}', line)
  end)

  it('in struct', function()
    vim.bo.filetype = 'rust'
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      'struct Test {',
      '    username',
      '}',
    })
    vim.treesitter.start(bufnr, 'rust')
    vim.api.nvim_win_set_cursor(0, { 2, 11 })
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

  it('rust closure symbol', function()
    vim.bo[bufnr].filetype = 'rust'
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      'fn main() {',
      '    let test = fs::read_to_string("foo/bar").unwrap_or_else()',
      '}',
    })
    vim.cmd('TSBufEnable highlight')
    vim.api.nvim_win_set_cursor(0, { 2, 59 })
    feedkey('\\')
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[2]
    eq('    let test = fs::read_to_string("foo/bar").unwrap_or_else(|| {})', line)
  end)
end)
