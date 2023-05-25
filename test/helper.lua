local function t(s)
  return vim.api.nvim_replace_termcodes(s, true, true, true)
end

local function feedkey(key)
  vim.api.nvim_feedkeys(t('a' .. key), 'x', false)
end

local function join_paths(...)
  local result = table.concat({ ... }, '/')
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

return {
  feedkey = feedkey,
  treesitter_dep = treesitter_dep,
}
