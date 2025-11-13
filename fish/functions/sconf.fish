function sconf --description "Syncs the local config repository with the remote one"
    cd $XDG_CONFIG_HOME && git pull && git push
end
