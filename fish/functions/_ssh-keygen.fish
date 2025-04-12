function _ssh-keygen
  argparse 'h/help' -- $argv
  or return

  set -l hm '新しいssh鍵を適切に生成する。第一引数として鍵の名前を指定すること。.ssh/<name>/ にキーペアを生成する'
  if set -q _flag_help
      echo $hm
      return 0
  end

  set name $argv[1]
  if test -z "$name"
      echo '鍵の名前を指定してください'
      echo $hm
      return 1
  end
  mkdir -p "$HOME/.ssh/$name"
  ssh-keygen -t ed25519 -f "$HOME/.ssh/$name/id_ed25519"
  chmod 600 "$HOME/.ssh/$name/id_ed25519"
end

