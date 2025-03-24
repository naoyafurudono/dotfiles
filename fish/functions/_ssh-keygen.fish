function _ssh-keygen -d '新しいssh鍵を適切に生成する。第一引数として鍵の名前を指定すること。.ssh/<name>/ をmkdirする'
  set name $argv[1]
  mkdir -p "$HOME/.ssh/$name"
  ssh-keygen -t ed25519 -f "$HOME/.ssh/$name/id_ed25519"
  chmod 600 "$HOME/.ssh/$name/id_ed25519"
end
