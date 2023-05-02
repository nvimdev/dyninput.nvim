local api = vim.api
local nvim_buf_set_keymap = api.nvim_buf_set_keymap

local function flush_new(opt, new)
  api.nvim_buf_set_text(opt.buf, opt.lnum - 1, opt.col, opt.lnum - 1, opt.col, { new })
  api.nvim_win_set_cursor(0, { opt.lnum, opt.col + #new })
end

local function buf_map(buf, item)
  local mut, mut_rules = unpack(item)

  nvim_buf_set_keymap(buf, 'i', mut, '', {
    noremap = true,
    nowait = true,
    callback = function()
      local opt = {
        buf = buf,
      }
      opt.lnum, opt.col = unpack(api.nvim_win_get_cursor(0))
      local rules = type(mut_rules[1]) == 'table' and mut_rules or { mut_rules }

      for _, rule in ipairs(rules) do
        local new, filter = unpack(rule)
        if filter(opt) then
          local pos = new:find('!')
          if not pos then
            flush_new(opt, new)
            return
          end

          local new_col = pos + opt.col - 1
          print(pos, new_col)
          new = new:gsub('!', '')
          api.nvim_buf_set_text(opt.buf, opt.lnum - 1, opt.col, opt.lnum - 1, opt.col, { new })
          api.nvim_win_set_cursor(0, { opt.lnum, new_col })
        end
      end

      flush_new(opt, mut)
    end,
  })
end

local function create_event(ft, config)
  local tuples = {}
  for mut, rules in pairs(config) do
    tuples[#tuples + 1] = { mut, rules }
  end

  api.nvim_create_autocmd('FileType', {
    group = api.nvim_create_augroup('MutChar', { clear = false }),
    pattern = ft,
    callback = function(arg)
      vim.iter(tuples):map(function(item)
        buf_map(arg.buf, item)
      end)
    end,
  })
end

local function setup(config)
  for k, v in pairs(config) do
    create_event(k, v)
  end
end

return {
  setup = setup,
}
