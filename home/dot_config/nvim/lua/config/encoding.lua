local M = {}

-- colorme 配下の PHP/tpl は euc-jp（mail/ は除外）
function M.detect(filepath)
  if not filepath or filepath == '' then return nil end
  if not filepath:match('/colorme/') then return nil end
  if filepath:match('/mail/') then return nil end
  if filepath:match('%.php$') or filepath:match('%.tpl$') then
    return 'euc-jp'
  end
  return nil
end

return M
