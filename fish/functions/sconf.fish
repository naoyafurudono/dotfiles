function sconf --description "Syncs the local config repository with the remote one"
    _ = (cd $XDG_CONFIG_HOME && git add -A && git commit -m "Sync config" && git pull && git push)
end
