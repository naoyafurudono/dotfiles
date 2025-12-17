complete -c hustle -f
complete -c hustle -n "not __fish_seen_subcommand_from new list done" -a done   -d 'タスクを終了' -k
complete -c hustle -n "not __fish_seen_subcommand_from new list done" -a resume -d '作業を再開' -k
complete -c hustle -n "not __fish_seen_subcommand_from new list done" -a new    -d 'タスクを開始' -k
