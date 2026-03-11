complete -c hustle -f
complete -c hustle -n "not __fish_seen_subcommand_from new resume done clean" -a clean  -d 'マージ/クローズ済みPRのworktreeを削除' -k
complete -c hustle -n "not __fish_seen_subcommand_from new resume done clean" -a done   -d 'タスクを終了' -k
complete -c hustle -n "not __fish_seen_subcommand_from new resume done clean" -a resume -d '作業を再開' -k
complete -c hustle -n "not __fish_seen_subcommand_from new resume done clean" -a new    -d 'タスクを開始' -k
