#!/bin/bash
# mise等のWARNを抑制
export MISE_QUIET=1
# クリップボードにFinderでコピーしたファイルがあればPOSIXパスを返す
furl=$(osascript -e 'the clipboard as «class furl»' 2>/dev/null) || exit 1
hfs_path=${furl#file }
osascript -e "POSIX path of \"$hfs_path\"" 2>/dev/null
