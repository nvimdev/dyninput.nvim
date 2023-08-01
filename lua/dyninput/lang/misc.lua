local api = vim.api
local util = require('dyninput.util')
local ms = {}

function ms.is_pointer(opt)
  local curnode = util.ts_cursor_node(opt)
  if not curnode then
    return
  end
  local curword = vim.treesitter.get_node_text(curnode, opt.buf)
  local parent = curnode:parent()
  while parent do
    if parent:named_child_count() > 0 and util.ts_iter_all_children(parent, curword, opt) then
      return true
    end
    parent = parent:parent()
    if parent then
      local _, _, erow = vim.treesitter.get_node_range(parent)
      if erow < opt.lnum - 1 then
        break
      end
    end
  end
  return false
end

function ms.semicolon_in_lua(opt)
  local curnode = util.ts_cursor_node(opt)
  if not curnode then
    return
  end
  local word = util.ts_cursor_word(opt)
  if word == 'self' or curnode:type() == 'identifier' then
    return true
  end
end

function ms.generic_in_cpp()
  local text = api.nvim_get_current_line()
  if text == 'template' then
    return true
  end
  return false
end

function ms.go_variable_define(opt)
  local curnode = util.ts_cursor_node(opt)
  if not curnode then
    return
  end
  local parent = util.ts_parent_node_type(opt)
  if curnode:type() == 'identifier' and (parent == 'block' or parent == 'ERROR') then
    return true
  end
end

function ms.go_struct_field(opt)
  local parent = util.ts_parent_node_type(opt)
  if parent and parent == 'literal_element' then
    return true
  end
end

function ms.snake_case(opt)
  local curtype = util.ts_cursor_type(opt)
  if curtype and (curtype == 'string_literal' or curtype == 'string_content') then
    return false
  end
  return util.snake_case(opt)
end

return ms
