function __envchain_list_namespaces
    envchain --list 2>/dev/null
end

complete -c envchain -n "not __fish_seen_subcommand_from" -xa "(__envchain_list_namespaces)" -d "Namespace"
complete -c envchain -n "not __fish_seen_subcommand_from" -l list -d "List available namespaces"
complete -c envchain -n "not __fish_seen_subcommand_from" -l help -d "Show help"
complete -c envchain -n "not __fish_seen_subcommand_from" -l version -d "Show version"

# Provide environment variable completion when a namespace is selected
function __envchain_env_vars
    set -l namespace (commandline -opc)[2]
    envchain $namespace env | cut -d= -f1 2>/dev/null
end

complete -c envchain -n "__fish_seen_subcommand_from (__envchain_list_namespaces)" -xa "(__envchain_env_vars)" -d "Environment variable"

