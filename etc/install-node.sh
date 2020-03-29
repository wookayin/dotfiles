#!/bin/bash
# Auto-install node locally

RED="\033[0;31m";
GREEN="\033[0;32m";
YELLOW="\033[0;33m";
WHITE="\033[1;37m";
CYAN="\033[0;36m";
RESET="\033[0m";

node_version=$(node --version 2>/dev/null)
if [[ -n "$node_version" ]]; then
    echo -e "${GREEN}node.js $node_version:${RESET} $(which node)"
else
    echo -e "${YELLOW}Node.js not found. Please install node.js v10.0+ by either:

  (a) Install node on the system (apt-get install nodejs, or brew install nodejs)
  (b) Install node using nvm (https://github.com/nvm-sh/nvm#installation-and-update)
  (c) RECOMMENDED: Install locally (i.e. on ~/.local/),
      $ dotfiles install node           # or,
      $ curl -sL install-node.now.sh | bash -s -- --prefix=\$HOME/.local --verbose
${RESET}"

    # Auto-install upon confirmation (Linux only)
    if [[ -n "$BASH_VERSION" ]] && [ `uname` == "Linux" ]; then
        while true; do
            echo -en "${YELLOW}Do you want to install node.js into ~/.local [y/N] ${RESET}"
            [ -t 1 ] && read -t 10 -p "(wait 10 secs for auto-yes) ? " user_prompt;
            if [ $? -ne 0 ]; then user_prompt="y"; fi  # when timeout, yes
            case $user_prompt in
                [YyNn]* ) break;;
                *) echo "Please answer yes or no.";;
            esac
        done
        if [[ "$user_prompt" == [Yy]* ]]; then
            echo -e "\n${GREEN}Installing node.js into ~/.local/ ...${RESET}";
            dotfiles install node && exit 0;
        fi
    fi

    exit 1;
fi
