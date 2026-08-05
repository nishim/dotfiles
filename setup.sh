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

# ~/.claude 配下は symlink で管理（実体ディレクトリが残っていれば .bak に退避）
mkdir -p ~/.claude
link_claude_dir() {
  src="$1"
  dst="$2"
  if [ -d "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak"
  fi
  ln -sfn "$src" "$dst"
}
link_claude_dir "$PWD/agents/claude/skills" ~/.claude/skills
link_claude_dir "$PWD/agents/claude/commands" ~/.claude/commands
link_claude_dir "$PWD/agents/claude/agents" ~/.claude/agents
