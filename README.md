# pass

```bash
chmod 700 ~/.ssh && chmod 600 ~/.ssh/*
export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
gpgconf --launch gpg-agent
gpg-connect-agent updatestartuptty /bye
```
