local M = {}

-- nkf --guess の出力を Vim の fileencoding 名にマップする
local function map_nkf(guess)
  if not guess then return nil end
  -- 先頭の encoding 名のみ見る ("UTF-8 (LF)" → "UTF-8")
  local name = guess:match('^[%w_-]+')
  if not name then return nil end
  name = name:upper()
  if name == 'EUC-JP' then return 'euc-jp' end
  if name == 'SHIFT_JIS' or name == 'CP932' or name == 'SHIFT-JIS' then return 'cp932' end
  if name == 'ISO-2022-JP' then return 'iso-2022-jp' end
  -- UTF-8 / US-ASCII / BINARY 等は上書き不要
  return nil
end

-- nkf による文字コード判定。PHP/tpl など日本語混在ファイル向け
function M.detect(filepath)
  if not filepath or filepath == '' then return nil end
  if vim.fn.executable('nkf') ~= 1 then return nil end
  if vim.fn.filereadable(filepath) ~= 1 then return nil end
  local guess = vim.fn.system({ 'nkf', '--guess', filepath })
  if vim.v.shell_error ~= 0 then return nil end
  return map_nkf(vim.fn.trim(guess))
end

return M
