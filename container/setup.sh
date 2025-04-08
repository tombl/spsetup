#!/usr/bin/env bash

# Prevent prompts about restarting services
export DEBIAN_FRONTEND=noninteractive

# Update package list
apt-get update

# Add repositories
apt-get -y install software-properties-common apt-transport-https gnupg wget ca-certificates

# Sublime Text
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/sublimehq-archive.gpg
echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list

# VS Code
wget -qO - https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | tee /etc/apt/sources.list.d/vscode.list


# Install packages
apt-get update && apt-get -y upgrade

# Editors and such
packages+=(build-essential neovim vim-gtk3 emacs sublime-text code idle-python3.12 gedit-plugins geany-plugins)

# Extra Compilers
packages+=(clang)

# Official Compiler Versions (TODO: which version of ubuntu?)
packages+=(gcc g++)
packages+=(openjdk-17-jdk openjdk-17-jre)
packages+=(pypy3)

apt-get -y install "${packages[@]}"

# Finalise package list
apt-get -y autoremove && apt-get -y autoclean

# Distrobox specifics
ln -s /usr/bin/distrobox-host-exec /usr/local/bin/spsetup
