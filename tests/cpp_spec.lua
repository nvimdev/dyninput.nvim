describe('mutchar in cpp', function()
  before_each(function()
    local bufnr = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_win_set_buf(0, bufnr)
    vim.bo[bufnr].filetype = 'cpp'
  end)

  it('generic after template keyword', function()
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'template' })
    vim.api.nvim_input(',')
    local line = api.nvim_buf_get_lines(bufnr, 0, -1, false)[1]
    assert.are.same('template <>', line)
  end)
end)
