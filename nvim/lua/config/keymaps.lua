-- Cmd+S で保存
vim.keymap.set({ 'n', 'i', 'v' }, '<D-s>', '<Cmd>write<CR>', { desc = 'Save file' })

-- 診断のキーマップ
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = '前の診断へ' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = '次の診断へ' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = '診断を表示' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = '診断一覧' })

-- フローティングターミナル
local term_buf = nil
local term_win = nil

local function toggle_terminal()
  -- ウィンドウが開いていれば閉じる
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_hide(term_win)
    term_win = nil
    return
  end

  -- バッファがなければ作成
  if not term_buf or not vim.api.nvim_buf_is_valid(term_buf) then
    term_buf = vim.api.nvim_create_buf(false, true)
  end

  -- ウィンドウサイズを計算
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- フローティングウィンドウを開く
  term_win = vim.api.nvim_open_win(term_buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' Terminal ',
    title_pos = 'center',
  })

  -- ターミナルがまだ起動していなければ起動
  if vim.bo[term_buf].buftype ~= 'terminal' then
    vim.cmd('terminal')
  end

  -- インサートモードに入る
  vim.cmd('startinsert')
end

vim.keymap.set('n', '<leader>t', toggle_terminal, { desc = 'Toggle terminal' })
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('t', '<C-t>', function()
  toggle_terminal()
end, { desc = 'Hide terminal' })

-- ターミナルでgf: ターミナルを隠してファイルを開く
vim.api.nvim_create_autocmd('TermOpen', {
  callback = function()
    vim.keymap.set('n', 'gf', function()
      local file = vim.fn.expand('<cfile>')
      toggle_terminal()
      vim.cmd('edit ' .. file)
    end, { buffer = true, desc = 'Open file and hide terminal' })
  end,
})
