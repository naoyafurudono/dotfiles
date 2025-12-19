function hustle -d 'Claude Codeタスク管理'
    if test (count $argv) -eq 0
        echo "Claude Codeタスク管理"
        echo "Usage: hustle <command>"
        echo ""
        echo "Commands:"
        echo "  new    タスクを開始"
        echo "  resume 作業を再開"
        echo "  done   タスクを終了"
        echo "  clean  マージ/クローズ済みPRのworktreeを削除"
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

            # タスク内容を入力（エディタで複数行）
            set tmpfile (mktemp)
            nvim "$tmpfile"
            set task_description (cat "$tmpfile" | string collect)
            rm "$tmpfile"
            test -n "$task_description"; or return 1

            # Claude にブランチ名を提案させる
            set prompt "以下のタスク内容から、gitブランチ名を1つだけ提案してください。
ルール:
- 英語の小文字とハイフンのみ使用
- 30文字以内
- プレフィックスなし（feature/などは不要）
- ブランチ名のみ出力、説明不要

タスク: $task_description"

            set suggested_branch (spinner "ブランチ名を考え中..." "claude -p '$prompt' --model haiku" | string trim)

            # 確認・編集
            read -P "ブランチ名 [$suggested_branch]> " branch_name
            test -z "$branch_name"; and set branch_name "$suggested_branch"

            # worktree 作成
            set worktree_dir "../"(basename (pwd))"-$branch_name"
            git worktree add -b "$branch_name" "$worktree_dir" origin/main

            # worktree に移動して Claude Code 起動
            cd "$worktree_dir"
            claude "$task_description

ultrathink"

        case resume
            set worktree (git worktree list --porcelain | grep '^worktree ' | sed 's/worktree //' | fzf --prompt="worktree> ")
            test -n "$worktree"; or return 1
            cd "$worktree"
            claude -c

        case done
            set current (pwd)
            set main_worktree (git worktree list --porcelain | grep '^worktree ' | head -1 | sed 's/worktree //')

            if test "$current" = "$main_worktree"
                echo "Cannot remove main worktree" >&2
                return 1
            end

            cd "$main_worktree"
            rm -rf "$current"
            git worktree prune
            echo "Removed: $current"

        case clean
            set main_worktree (git worktree list --porcelain | grep '^worktree ' | head -1 | sed 's/worktree //')
            set worktrees (git worktree list --porcelain | grep '^worktree ' | sed 's/worktree //')

            for wt in $worktrees
                # メインworktreeはスキップ
                test "$wt" = "$main_worktree"; and continue

                # worktreeのブランチ名を取得
                set branch (git -C "$wt" rev-parse --abbrev-ref HEAD 2>/dev/null)
                test -z "$branch"; and continue

                # PRの状態を確認
                set pr_state (gh pr view "$branch" --json state --jq '.state' 2>/dev/null)

                if test "$pr_state" = "MERGED" -o "$pr_state" = "CLOSED"
                    echo "Removing $wt (PR: $pr_state)"
                    rm -rf "$wt"
                end
            end

            git worktree prune
            echo "Clean completed"

        case '*'
            echo "Unknown command: $argv[1]" >&2
            echo "" >&2
            echo "Usage: hustle <command>" >&2
            echo "" >&2
            echo "Commands:" >&2
            echo "  new    タスクを開始" >&2
            echo "  resume 作業を再開" >&2
            echo "  done   タスクを終了" >&2
            echo "  clean  マージ/クローズ済みPRのworktreeを削除" >&2
            return 1
    end
end
