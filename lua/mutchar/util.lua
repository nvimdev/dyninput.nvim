local treesitter, api = vim.treesitter, vim.api

local function ts_node_match(type, word, opt)
  local lang = treesitter.language.get_lang(vim.bo[opt.buf].filetype)
  if not lang then
    return
  end
  local query = treesitter.query.get(lang, 'highlights')
  if not query then
    return
  end
  local curnode = treesitter.get_node({ bufnr = opt.buf })
  if not curnode then
    return
  end
  local first = treesitter.get_node({ bufnr = opt.buf, pos = { 0, 0 } })
  if not first then
    return
  end
  local root = first:parent()
  if not root then
    return
  end

  for id, node, _ in query:iter_captures(root, opt.buf, 0, opt.lnum) do
    local name = query.captures[id]
    local text = treesitter.get_node_text(node, opt.buf)
    print(name, '|', text, '|', word)
    if text == word and vim.tbl_contains(type, name) then
      return true
    end
  end
end

local function word_before(opt)
  local line = api.nvim_buf_get_text(opt.buf, opt.lnum - 1, 0, opt.lnum - 1, opt.col, {})[1]
  local word = string.match(line:sub(1, opt.col), '%w+$') or nil
  return word
end

return {
  ts_node_match = ts_node_match,
  word_before = word_before,
}
