function sconf --description "Syncs the local config repository with the remote one"
    set -l repo_dir (chezmoi source-path | string replace '/home' '')
    chezmoi re-add
    _ (cd $repo_dir && git add -A && git commit -m "update" && git pull && git push)
end
