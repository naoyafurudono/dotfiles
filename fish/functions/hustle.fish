function hustle -d 'Claude Codeタスク管理'
    if test (count $argv) -eq 0
        echo "Usage: hustle <command>"
        echo ""
        echo "Commands:"
        echo "  new   タスクを開始"
        echo "  list  作業を再開"
        echo "  done  タスクを終了"
        return 0
    end

    switch $argv[1]
        case new
            # リポジトリを選択
            if not git rev-parse --is-inside-work-tree &>/dev/null
                set root (ghq root)
                set selected (ghq list | fzf --prompt="リポジトリ> ")
                test -n "$selected"; or return 1
                cd "$root/$selected"
            end

            # origin/main と同期
            git fetch origin

            # タスク内容を入力
            read -P "タスク内容> " task_description
            test -n "$task_description"; or return 1

            # Claude にブランチ名を提案させる
            set prompt "以下のタスク内容から、gitブランチ名を1つだけ提案してください。
ルール:
- 英語の小文字とハイフンのみ使用
- 30文字以内
- プレフィックスなし（feature/などは不要）
- ブランチ名のみ出力、説明不要

タスク: $task_description"

            set suggested_branch (claude -p "$prompt" 2>/dev/null | string trim)

            # 確認・編集
            read -P "ブランチ名 [$suggested_branch]> " branch_name
            test -z "$branch_name"; and set branch_name "$suggested_branch"

            # worktree 作成
            set worktree_dir "../"(basename (pwd))"-$branch_name"
            git worktree add -b "$branch_name" "$worktree_dir" origin/main

            # worktree に移動して Claude Code 起動
            cd "$worktree_dir"
            claude

        case list
            set worktree (git worktree list --porcelain | grep '^worktree ' | sed 's/worktree //' | fzf --prompt="worktree> ")
            test -n "$worktree"; or return 1
            cd "$worktree"
            claude

        case done
            set current (pwd)
            set main_worktree (git worktree list --porcelain | grep '^worktree ' | head -1 | sed 's/worktree //')

            cd "$main_worktree"
            git worktree remove "$current"
            echo "Removed: $current"
    end
end
