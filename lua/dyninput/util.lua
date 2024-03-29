local api = vim.api
local treesitter = vim.treesitter

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

local function ts_cursor_type(opt)
  local curnode = ts_cursor_node(opt)
  if not curnode then
    return
  end
  return curnode:type()
end

local function ts_cursor_word(opt)
  local curnode = ts_cursor_node(opt)
  if not curnode then
    return
  end
  return vim.treesitter.get_node_text(curnode, opt.buf)
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

local function has_space_before(opt)
  local before = vim.api.nvim_buf_get_text(opt.buf, opt.lnum, opt.col - 1, opt.lnum, opt.col, {})[1]
  if before == ' ' then
    return true
  end
  return false
end

local function line_parts(opt)
  local line = api.nvim_buf_get_text(opt.buf, opt.lnum - 1, 0, opt.lnum - 1, opt.col, {})[1]
  return vim.split(line, '%s')
end

local function snake_case(opt)
  local parts = line_parts(opt)
  local word = parts[#parts]
  local curnode = ts_cursor_node(opt)
  --ignore in string
  if curnode and curnode:type() == 'string_literal' then
    return
  end

  if word:find('%d') then
    return
  end
  if word:find('[%.%->]') then
    word = word:match('[%.%->]+([%a_][%w_]*)')
  end

  if word and word:find('^%a[%a%d_]*$') then
    return true
  end
end

local function ts_iter_all_children(tsnode, word, opt)
  local function range_children(node)
    if node:child_count() == 0 then
      return
    end
    for n in node:iter_children() do
      local text = vim.treesitter.get_node_text(n, opt.buf)
      if text == word and n:parent():type() == 'pointer_declarator' then
        return true
      end
      local res = range_children(n)
      if res then
        return res
      end
    end
  end

  return range_children(tsnode)
end

return {
  ts_parent_node_type = ts_parent_node_type,
  ts_cursor_hl = ts_cursor_hl,
  ts_highlight_query = ts_highlight_query,
  ts_cursor_node = ts_cursor_node,
  ts_cursor_type = ts_cursor_type,
  ts_cursor_word = ts_cursor_word,
  ts_blank_node_parent = ts_blank_node_parent,
  ts_hl_match = ts_hl_match,
  has_space_before = has_space_before,
  line_parts = line_parts,
  snake_case = snake_case,
  ts_iter_all_children = ts_iter_all_children,
}
