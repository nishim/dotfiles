eval "$(mise activate zsh)"

if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

  autoload -Uz compinit
  compinit
fi

export CLICOLOR=1

PATH=~/go/bin/:$PATH

alias vi='vim'

#alias pwgen='cat /dev/urandom | LC_CTYPE=C tr -dc 'a-z0-9' | fold -w 16 | head -n 32'
#

#
# asdf
# https://asdf-vm.com/
#
# Plugins
# - https://github.com/asdf-community/asdf-python
#
#export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

source ~/.zsh/git-prompt.sh
fpath=(~/.zsh $fpath)
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
autoload -Uz compinit && compinit
GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUPSTREAM=auto
setopt PROMPT_SUBST ; PS1='%F{green}%n@%m%f: %F{cyan}%~%f %F{red}$(__git_ps1 "(%s)")%f\$ '


# aliases & functions
list-ec2() {
  if [[ "$1" = "--profile" && -n "$2" ]]; then
    aws ec2 describe-instances --profile "$2" | jq '.Reservations[] .Instances[] | [.ImageId, .InstanceId, .Tags[].Value]'
    shift 2
  else
    aws ec2 describe-instances | jq '.Reservations[] .Instances[] | [.ImageId, .InstanceId, .Tags[].Value]'
  fi

  echo
  echo "Next Action"
  echo "- Start a session using SSM."
  echo "  aws ssm start-session --profile \$PROFILE --target \$INSTANCE_ID"
  echo
  echo "- Start a port forwarding using SSM."
  echo "  aws ssm start-session \ "
  echo "      --profile \$PROFILE \ "
  echo "      --target  \$INSTANCE_ID \ "
  echo "      --document-name AWS-StartPortForwardingSessionToRemoteHost \ "
  echo "      --parameters 'portNumber=\$REMOTE_PORT,localPortNumber=\$LOCAL_PORT,host=\$DESTINATION_HOST'"
}

sound() {
  afplay /System/Library/Sounds/Ping.aiff
  afplay /System/Library/Sounds/Ping.aiff
  afplay /System/Library/Sounds/Ping.aiff
}

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/yuji/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/yuji/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/yuji/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/yuji/Downloads/google-cloud-sdk/completion.zsh.inc'; fi


# bun completions
[ -s "$HOME/.bun/_bun" ] && source "/Users/yuji/.bun/_bun"

## bun
#export BUN_INSTALL="$HOME/.bun"
#export PATH="$BUN_INSTALL/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/yuji/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

jupyter-notebook-setup() {
  python -m venv venv
  source venv/bin/activate
  pip install --upgrade pip
  pip install jupyter notebook ipykernel
  pip install pandas numpy matplotlib seaborn
  # Excel
  pip install openpyxl xlrd
  # Web
  pip install requests beautifulsoup4
  # ML
  pip install scikit-learn

  pip freeze > requirements.txt

  cat << EOS > my.ipynb
{
    "cells": [
        {
            "cell_type":"markdown",
            "metadata": {},
            "source": [
                "## My Notebook"
            ]
        },
        {
            "cell_type":"code",
            "execution_count":null,
            "metadata": {},
            "outputs": [],
            "source": [
                "import pandas as pd\n",
                "import numpy as np\n",
                "import os\n",
                "import json\n",
                "import math\n",
                "from datetime import datetime, date\n",
                "from pathlib import Path\n",
                "import openpyxl\n",
                "from typing import Dict, List, Optional, Union"
            ]
        }
    ],
    "metadata": {
        "kernelspec": {
            "display_name":"Python (myproject)",
            "language":"python",
            "name":"myproject"
        },
        "language_info": {
            "codemirror_mode": {
                "name":"ipython",
                "version":3
            },
            "file_extension":".py",
            "mimetype":"text/x-python",
            "name":"python",
            "nbconvert_exporter":"python",
            "pygments_lexer":"ipython",
            "version":"3.11.13"
        }
    },
    "nbformat":4,
    "nbformat_minor":5
}
EOS
}

# 認証情報・会社固有設定は git 管理外の ~/.zshrc.local に置く
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
