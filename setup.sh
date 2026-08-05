#!/bin/sh

PWD=$(pwd -P)

ln -fs $PWD/.editorconfig ~/.editorconfig
ln -fs $PWD/.gitconfig ~/.gitconfig
ln -fs $PWD/.gitignore ~/.gitignore
ln -fs $PWD/.gitignore ~/.gitignore
ln -fs $PWD/.vimrc ~/.vimrc
ln -fs $PWD/.zshrc ~/.zshrc
mkdir -p ~/.config/mise/
ln -fs $PWD/.config/mise/config.toml ~/.config/mise/config.toml


mkdir -p ~/.zsh
ln -fs $PWD/git-prompt.sh ~/.zsh/git-prompt.sh
ln -fs $PWD/git-completion.bash ~/.zsh/git-completion.bash
ln -fs $PWD/git-completion.zsh ~/.zsh/_git

mkdir -p ~/.terraform.d/plugin-cache
ln -fs $PWD/.terraformrc ~/.terraformrc

mkdir -p ~/.claude/skills
rsync -a --delete "$PWD/agents/common/skills/" ~/.claude/skills/
