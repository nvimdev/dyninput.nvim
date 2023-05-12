local function ts_node_in_cursor(bufnr)
  local result = {}
  local win = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(win)
  local row, col = cursor[1] - 1, cursor[2] - 1

  for _, capture in pairs(vim.treesitter.get_captures_at_pos(bufnr, row, col)) do
    capture.hl_group = '@' .. capture.capture .. '.' .. capture.lang
    result[#result + 1] = capture
  end
  return result
end

return {
  ts_node_in_cursor = ts_node_in_cursor,
}
