#!/bin/bash
# validate neovim package installation on python2/3 and automatically install if missing

set -e

RED="\033[0;31m";
GREEN="\033[0;32m";
YELLOW="\033[0;33m";
WHITE="\033[1;37m";
CYAN="\033[0;36m";
RESET="\033[0m";

_version_check() {
    curver="${1/v/}"; targetver="$2";
    [ "$targetver" = "$(echo -e "$curver\n$targetver" | sort -V | head -n1)" ]
}
NVIM_RECOMMENDED_VERSION="0.9.2"
neovim_current_verson=$(nvim --version 2>/dev/null | head -n1 | cut -d' ' -f2)

if which nvim >/dev/null && _version_check "$neovim_current_verson" "$RECOMMENDED_VERSION"; then
    echo -e "neovim found at ${GREEN}$(which nvim) ($neovim_current_verson)${RESET}"

else
    # neovim not found. install one!
    if [ `uname` == "Darwin" ]; then
        NEOVIM_INSTALL_CMD="brew install neovim"
    else
        NEOVIM_INSTALL_CMD="dotfiles install neovim"
    fi
    if ! which nvim >/dev/null; then
        echo -e "${RED}Neovim not found."
    else
        echo -e "${RED}Neovim is outdated (recommended >= $RECOMMENDED_VERSION): $(nvim --version | head -1)"
    fi
    echo -e "Please install using '${NEOVIM_INSTALL_CMD}'.${RESET}"

    # Automatically install dotfiles upon confirmation (Linux only)
    if [[ -n "$BASH_VERSION" ]] && [ `uname` == "Linux" ]; then
        while true; do
            echo -en "${YELLOW}Do you want to install neovim locally [y/N] ${RESET}"
            [ -t 1 ] && read -t 5 -p "(wait 5 secs for auto-yes) ? " user_prompt || user_prompt="y";
            case $user_prompt in
                [YyNn]* ) break;;
                *) echo "Please answer yes or no.";;
            esac
        done
        if [[ "$user_prompt" == [Yy]* ]]; then
            echo -e "\n${GREEN}Installing neovim into ~/.local/bin/ ...${RESET}";
            $HOME/.dotfiles/bin/dotfiles install neovim && exit 0;
        fi
    fi

    exit 1;
fi
