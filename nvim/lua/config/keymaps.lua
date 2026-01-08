-- 診断のキーマップ
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = '前の診断へ' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = '次の診断へ' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = '診断を表示' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = '診断一覧' })

-- grep
vim.keymap.set('n', '<leader>g', ':Rg ', { desc = 'Grep' })
