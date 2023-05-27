local treesitter, api = vim.treesitter, vim.api

local function word_before(opt)
  local line = api.nvim_buf_get_text(opt.buf, opt.lnum - 1, 0, opt.lnum - 1, opt.col, {})[1]
  local res = vim.split(line, '%s')
  return res[#res]
end

local function char_before(opt)
  local char =
    api.nvim_buf_get_text(opt.buf, opt.lnum - 1, opt.col - 1, opt.lnum - 1, opt.col, {})[1]
  return char
end

local function ts_highlight_query(buf)
  local lang = treesitter.language.get_lang(vim.bo[buf].filetype)
  if not lang then
    return
  end
  return treesitter.query.get(lang, 'highlights')
end

local function ts_cursor_node(opt)
  local curnode = treesitter.get_node({ bufnr = opt.buf, pos = { opt.lnum - 1, opt.col - 1 } })
  return curnode
end

local function ts_cursor_hl(opt)
  local res = vim.inspect_pos(opt.buf, opt.lnum - 1, opt.col - 1)
  return res.treesitter
end

local function ts_parent_node_type(opt)
  local curnode = ts_cursor_node(opt)
  if not curnode then
    return
  end
  local parent = curnode:parent()
  if not parent then
    return
  end
  return parent:type()
end

local function ts_blank_node_parent(buf)
  local blank = treesitter.get_node({ bufnr = buf })
  if not blank then
    return
  end
  local parent = blank:parent()
  if not parent then
    return
  end
  return parent:type()
end

local function ts_hl_match(type, word, opt)
  local query = ts_highlight_query(opt.buf)
  if not query then
    return
  end
  local curnode = ts_cursor_node(opt)
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
    if text == word and vim.tbl_contains(type, name) then
      return true
    end
  end
end

return {
  ts_parent_node_type = ts_parent_node_type,
  ts_cursor_hl = ts_cursor_hl,
  ts_highlight_query = ts_highlight_query,
  ts_cursor_node = ts_cursor_node,
  ts_blank_node_parent = ts_blank_node_parent,
  ts_hl_match = ts_hl_match,
  word_before = word_before,
  char_before = char_before,
}
