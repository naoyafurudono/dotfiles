#!/bin/sh
# Git credential helper that selects the correct GitHub account based on remote URL.
# Uses `gh auth token --user` to get account-specific tokens without changing global state.
#
# Usage in git config:
#   [credential "https://github.com"]
#     helper = !/path/to/credential-helper.sh

# Organizations that should use the work account
WORK_ORGS="pepabo"  # スペース区切りのリスト
WORK_USER="naoya-furudono_pepabo"
DEFAULT_USER="naoyafurudono"

# Only handle "get" operations; delegate store/erase to gh directly
if [ "$1" != "get" ]; then
    exec gh auth git-credential "$@"
fi

# Read the credential request from stdin
input=$(cat)
host=$(echo "$input" | grep '^host=' | sed 's/^host=//')
path=$(echo "$input" | grep '^path=' | sed 's/^path=//')

# Only apply custom logic for github.com
if [ "$host" != "github.com" ]; then
    echo "$input" | gh auth git-credential get
    exit $?
fi

# Extract the org (first path component) from the URL path
org=$(echo "$path" | cut -d'/' -f1)

# Check if the org matches any work org
user="$DEFAULT_USER"
for work_org in $WORK_ORGS; do
    if [ "$org" = "$work_org" ]; then
        user="$WORK_USER"
        break
    fi
done

# Get the token for the selected user
token=$(gh auth token --user "$user" 2>/dev/null)
if [ -z "$token" ]; then
    # Fallback to default gh credential helper
    echo "$input" | gh auth git-credential get
    exit $?
fi

echo "protocol=https"
echo "host=github.com"
echo "username=$user"
echo "password=$token"
