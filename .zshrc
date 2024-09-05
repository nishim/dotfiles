eval "$(anyenv init -)"

if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

  autoload -Uz compinit
  compinit


  PATH=$(brew --prefix)/opt/postgresql@15/bin/:$PATH
fi

export CLICOLOR=1

PATH=~/go/bin/:$PATH

#alias pwgen='cat /dev/urandom | LC_CTYPE=C tr -dc 'a-z0-9' | fold -w 16 | head -n 32'


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
}
