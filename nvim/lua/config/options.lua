vim.g.mapleader = " "

-- 行番号の表示
vim.opt.number = true

-- True Color有効化
vim.opt.termguicolors = true

-- ripgrepを:grepで使用
vim.opt.grepprg = 'rg --vimgrep --smart-case'
vim.opt.grepformat = '%f:%l:%c:%m'

-- :Rg コマンド（最初のファイルにジャンプしない）
vim.api.nvim_create_user_command('Rg', function(opts)
  vim.cmd('silent grep! ' .. opts.args)
end, { nargs = '+' })

-- quickfixをフローティングウィンドウで開く（プレビュー付き）
local function open_qf_float()
  local qf_list = vim.fn.getqflist()
  if #qf_list == 0 then
    return
  end

  -- quickfixバッファを取得
  vim.cmd('copen')
  local qf_buf = vim.api.nvim_get_current_buf()
  vim.cmd('cclose')

  -- ウィンドウサイズを計算
  local width = math.floor(vim.o.columns * 0.8)
  local qf_height = math.min(#qf_list + 1, 10)
  local preview_height = math.floor(vim.o.lines * 0.4)
  local total_height = qf_height + preview_height + 1
  local row = math.floor((vim.o.lines - total_height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- タイトル
  local title = vim.fn.getqflist({ title = 0 }).title or 'Quickfix'

  -- 背景を覆うバッファとウィンドウ
  local backdrop_buf = vim.api.nvim_create_buf(false, true)
  local backdrop_win = vim.api.nvim_open_win(backdrop_buf, false, {
    relative = 'editor',
    width = vim.o.columns,
    height = vim.o.lines,
    row = 0,
    col = 0,
    style = 'minimal',
    focusable = false,
    zindex = 10,
  })
  vim.api.nvim_set_hl(0, 'QfBackdrop', { bg = '#000000', blend = 50 })
  vim.wo[backdrop_win].winhighlight = 'Normal:QfBackdrop'

  -- プレビュー用バッファ
  local preview_buf = vim.api.nvim_create_buf(false, true)

  -- プレビューウィンドウを開く（上）
  local preview_win = vim.api.nvim_open_win(preview_buf, false, {
    zindex = 20,
    relative = 'editor',
    width = width,
    height = preview_height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = 'Preview',
    title_pos = 'center',
  })

  -- quickfixウィンドウを開く（下）
  local qf_win = vim.api.nvim_open_win(qf_buf, true, {
    zindex = 20,
    relative = 'editor',
    width = width,
    height = qf_height,
    row = row + preview_height + 2,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = title,
    title_pos = 'center',
  })

  -- プレビュー更新関数
  local function update_preview()
    local idx = vim.fn.line('.')
    local item = qf_list[idx]
    if not item or item.bufnr == 0 then
      return
    end

    local filename = vim.api.nvim_buf_get_name(item.bufnr)
    local lnum = item.lnum
    local context = 5

    -- ファイル内容を読み込み
    local ok, lines = pcall(vim.fn.readfile, filename)
    if not ok then
      return
    end

    local start_line = math.max(1, lnum - context)
    local end_line = math.min(#lines, lnum + context)
    local preview_lines = {}
    for i = start_line, end_line do
      table.insert(preview_lines, lines[i])
    end

    vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, preview_lines)

    -- ハイライト行
    local hl_line = lnum - start_line
    vim.api.nvim_buf_clear_namespace(preview_buf, -1, 0, -1)
    if hl_line >= 0 and hl_line < #preview_lines then
      vim.api.nvim_buf_add_highlight(preview_buf, -1, 'Visual', hl_line, 0, -1)
    end

    -- ファイルタイプを設定（シンタックスハイライト）
    local ft = vim.filetype.match({ filename = filename })
    if ft then
      vim.bo[preview_buf].filetype = ft
    end
  end

  -- 初回プレビュー
  update_preview()

  -- カーソル移動時にプレビュー更新
  local augroup = vim.api.nvim_create_augroup('QfFloatPreview', { clear = true })
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = augroup,
    buffer = qf_buf,
    callback = function()
      if vim.api.nvim_buf_is_valid(preview_buf) then
        update_preview()
      end
    end,
  })

  -- 閉じる関数
  local function close_windows()
    vim.api.nvim_del_augroup_by_name('QfFloatPreview')
    pcall(vim.api.nvim_win_close, qf_win, true)
    pcall(vim.api.nvim_win_close, preview_win, true)
    pcall(vim.api.nvim_win_close, backdrop_win, true)
    pcall(vim.api.nvim_buf_delete, preview_buf, { force = true })
    pcall(vim.api.nvim_buf_delete, backdrop_buf, { force = true })
  end

  -- Enterでジャンプして閉じる
  vim.keymap.set('n', '<CR>', function()
    local idx = vim.fn.line('.')
    close_windows()
    vim.cmd('cc ' .. idx)
  end, { buffer = qf_buf })

  -- qまたはEscで閉じる
  vim.keymap.set('n', 'q', close_windows, { buffer = qf_buf })
  vim.keymap.set('n', '<Esc>', close_windows, { buffer = qf_buf })
end

-- grep後に自動でquickfixをフローティングで開く
vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  pattern = 'grep',
  callback = function()
    vim.schedule(open_qf_float)
  end,
})

-- quickfixフローティングを開くコマンド
vim.api.nvim_create_user_command('QfFloat', open_qf_float, {})
