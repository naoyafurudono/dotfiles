#!/bin/bash -eu

git clone https://github.com/naoyafurudono/dotfiles.git
bash dotfiles/setup.sh

if [ $! -eq 0 ]; then
  echo "Success!"
else
  echo "Failed!"
  exit 1
fi

