#!/bin/bash

set -eu

git clone https://github.com/naoyafurudono/dotfiles.git
bash -e dotfiles/setup.sh
echo "Success!"

