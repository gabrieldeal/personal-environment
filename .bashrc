# executed by bash for non-login shells.

source "$HOME/.bash_interactive"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/gabrielx/local/google-cloud-sdk/path.bash.inc' ]; then . '/home/gabrielx/local/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/gabrielx/local/google-cloud-sdk/completion.bash.inc' ]; then . '/home/gabrielx/local/google-cloud-sdk/completion.bash.inc'; fi

# pnpm
export PNPM_HOME="/home/g/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end