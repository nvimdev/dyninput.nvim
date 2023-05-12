local util = require('mutchar.util')
local ctx = {}

local function factory(fn)
  return function(opt)
    return fn(opt)
  end
end

---check diagnostic have the string
function ctx.diagnostic_match(patterns)
  patterns = type(patterns) == 'string' and { patterns } or patterns
  local function check_diag(opt)
    local diagnostics = vim.diagnostic.get(opt.buf, { lnum = opt.lnum - 1 })
    if next(diagnostics) == nil then
      return false
    end
    local it = vim.iter(diagnostics):find(function(item)
      return vim.iter(patterns):any(function(pattern)
        return item.message:find(pattern)
      end)
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

function ctx.semicolon_in_lua(opt)
  local text = vim.api.nvim_get_current_line()
  if text:sub(#text - 3, #text) == 'self' then
    return true
  end

  local nodes = util.ts_node_in_cursor(opt.buf)
  if vim.iter(nodes):any(function(item)
    return item.capture == 'variable'
  end) then
    return true
  end
end

-- function ctx.generic_in_rust(opt) end

function ctx.semicolon_in_rust(opt)
  local nodes = util.ts_node_in_cursor(opt.buf)
  if vim.iter(nodes):any(function(item)
    return item.capture == 'type'
  end) then
    return true
  end
  return false
end

function ctx.generic_in_cpp()
  local text = vim.api.nvim_get_current_line()
  if text == 'template' then
    return true
  end
  return false
end

return ctx
