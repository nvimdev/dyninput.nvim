local ctx = {}

local function factory(fn)
  return function(opt)
    return fn(opt)
  end
end

---check diagnostic have the string
function ctx.diagnostic_match(pattern)
  local function check_diag(opt)
    local diagnostics = vim.diagnostic.get(opt.buf, { lnum = opt.lnum - 1 })
    if next(diagnostics) == nil then
      return false
    end
    local it = vim.iter(diagnostics):find(function(item)
      return item.message:find(pattern)
    end)
    return it and true or false
  end
  return factory(check_diag)
end

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

function ctx.lsp_symbol_match(target)
  return function(opt)
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_active_clients({ buf = bufnr })
    local client = vim.iter(clients):find(function(item)
      return item.server_capabilities.documentSymbolProvider
    end)
    if not client then
      return false
    end

    local params = { textDocument = vim.lsp.util.make_text_document_params() }
    client.request('textDocument/documentSymbol', params, function(err, result, _)
      if err then
        return false
      end
      local index = binary_search(result, opt.lnum)
      local kind = result[index].kind
      if kind == target then
        return true
      end
    end, bufnr)
  end
end

local function find_space(opt)
  local before = vim.api.nvim_buf_get_text(opt.buf, opt.lnum, opt.col - 1, opt.lnum, opt.col, {})[1]
  if before == ' ' then
    return true
  end
  return false
end

function ctx.non_space_before(opt)
  if not find_space(opt) then
    return true
  end
  return false
end

function ctx.has_space_before(opt)
  return find_space(opt)
end

local function ts_query_and_node(opt)
  local current_node = vim.treesitter.get_node({
    bufnr = opt.buf,
    pos = { opt.lnum - 1, opt.col },
  })

  if not current_node then
    return
  end

  local parent_node = current_node:parent()
  if not parent_node then
    parent_node = current_node
  end
  local lang = vim.treesitter.language.get_lang(vim.bo[opt.buf].filetype)
  if not lang then
    return nil
  end

  local query = vim.treesitter.query.get(lang, 'highlights')

  return parent_node, query
end

---@private
local function ts_captures_at_line(opt)
  local parent_node, query = ts_query_and_node(opt)
  if not query or not parent_node then
    vim.notify('[mutchar.nvim] get treesitter query failed', vim.log.levels.ERROR)
    return
  end

  local types = {}
  for id, _, _ in query:iter_captures(parent_node, 0, opt.lnum, opt.lnum + 1) do
    local name = query.captures[id] -- name of the capture in the query
    -- local node_srow, _, node_erow, node_ecol = node:range()
    table.insert(types, name)
  end

  return types
end

---@private
local function equals_lnum_col(srow, erow, ecol, opt)
  ecol = ecol or nil
  if srow == opt.lnum and erow == opt.lnum then
    if not ecol then
      return true
    end
    if ecol == opt.col then
      return true
    else
      return false
    end
  end
  return false
end

---@private
local function tbl_filter(t1, t2)
  vim.validate({
    t1 = { t1, 't' },
    t2 = { t2, 't' },
  })
  local matched = false
  for _, need_match in pairs(t1) do
    for i, v in pairs(t2) do
      if need_match[i] == v then
        matched = true
      end
    end
    if matched then
      break
    end
  end

  return matched
end

local function ts_node_type_start()
  return {
    { 'keyword', 'type' },
    { 'keyword', 'variable' },
    { 'keyword.function', 'variable' },
  }
end

function ctx.semicolon_in_lua(opt)
  local text = vim.api.nvim_get_current_line()
  if text:sub(#text - 3, #text) == 'self' then
    return true
  end
  local types = ts_captures_at_line(opt)
  if not types then
    return false
  end
  if types[#types] == 'variable' then
    return true
  end
  return false
end

function ctx.generic_in_rust(opt)
  local parent_node, query = ts_query_and_node(opt)
  if not query or not parent_node then
    return
  end

  local types = {}
  local match_start = ts_node_type_start()
  local function ts_match_generic()
    if #types == 2 and tbl_filter(match_start, types) then
      return true
    end
    return false
  end

  for id, node, _ in query:iter_captures(parent_node, 0, opt.lnum, opt.lnum + 1) do
    local name = query.captures[id] -- name of the capture in the query
    table.insert(types, name)
    local srow, _, erow, ecol = node:range()
    if equals_lnum_col(srow, erow, ecol, opt) and ts_match_generic() then
      return true
    end
  end
  return false
end

function ctx.ret_arrow(opt)
  local types = ts_captures_at_line(opt)
  if not types then
    return false
  end

  local tbl = ts_node_type_start()[3]

  if types[1] == tbl[1] and types[2] == tbl[2] and types[#types] == 'punctuation.delimiter' then
    return true
  end
  return false
end

function ctx.semicolon_in_rust(opt)
  if find_space(opt) then
    return false
  end

  local parent_node, query = ts_query_and_node(opt)
  if not query or not parent_node then
    return false
  end

  for id, node, _ in query:iter_captures(parent_node, 0, opt.lnum, opt.lnum + 1) do
    local name = query.captures[id] -- name of the capture in the query
    local srow, _, erow, ecol = node:range()
    if equals_lnum_col(srow, erow, ecol, opt) and name == 'variable' then
      return true
    end
  end

  local text = vim.api.nvim_get_current_line()
  if opt.col == tonumber(vim.api.nvim_strwidth(text)) then
    return false
  end

  return true
end

function ctx.generic_in_cpp()
  local text = vim.api.nvim_get_current_line()
  if text == 'template' then
    return true
  end
  return false
end

return ctx
