local function binary_search(symbols, line)
  local left, right, mid = 1, #symbols, 0
  while true do
    mid = bit.rshift(left + right, 1)
    if mid == 0 then
      return nil
    end

    local range = symbols[mid].range or symbols[mid].selectionRange

    if line >= range.start.line and line <= range['end'].line then
      return mid
    elseif line < range.start.line then
      right = mid - 1
      if left > right then
        return nil
      end
    else
      left = mid + 1
      if left > right then
        return nil
      end
    end
  end
end

local function lsp_symbol_match(target, word)
  return function(opt)
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_active_clients({ buf = opt.bufnr })
    local client = vim.iter(clients):find(function(item)
      return item.server_capabilities.documentSymbolProvider
    end)
    if not client then
      return false
    end

    local params = { textDocument = vim.lsp.util.make_text_document_params() }
    local res = client.request_sync('textDocument/documentSymbol', params, bufnr)
    if not res or not res.result then
      return
    end
    for _, item in ipairs(res.result) do
      if item.kind == target and item.name == word then
        return true
      end
      if item.selectionRange.start.line + 1 == opt.lnum then
        return
      end
    end
  end
end

local function ts_node_match(target, word, opt)
  local lang = vim.treesitter.language.get_lang(vim.bo[opt.buf].filetype)
  if not lang then
    return
  end
  local query = vim.treesitter.query.get(lang, 'highlights')
  if not query then
    return
  end
  local curnode = vim.treesitter.get_node({ bufnr = opt.buf })
  if not curnode then
    return
  end
  local root = curnode:tree()
  if not root then
    return
  end

  local index = 0
  for id, node, _ in query:iter_captures(root:root(), opt.buf, 0, opt.lnum) do
    index = index + 1
    local name = query.captures[id]
    local text = vim.treesitter.get_node_text(node, opt.buf)
    if text == word and name == target then
      return true
    end
  end
end

local function word_before(opt, trim)
  trim = trim or true
  local words = vim.api.nvim_buf_get_text(opt.buf, opt.lnum - 1, 0, opt.lnum - 1, opt.col, {})
  if next(words) == nil then
    return
  end
  local res = vim.split(words[1], '%s')
  if not trim then
    return res[#res]
  end
  for i = 0, #res do
    if #res[#res - i] ~= 0 then
      return res[#res - i]
    end
  end
end

return {
  ts_node_match = ts_node_match,
  lsp_symbol_match = lsp_symbol_match,
  word_before = word_before,
}
