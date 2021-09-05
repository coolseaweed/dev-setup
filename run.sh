#!/bin/bash
set -e	
set -o pipefail

cd "$(dirname "${BASH_SOURCE}")";


function envSetup() {

    cp ~/.bashrc ~/.bashrc.orig
    cp ~/.vimrc ~/.vimrc.orig
    cp ./dot_files/.bashrc ./dot_files/.vimrc ~/;

    rm -rf ~/.vim/bundle
    git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    vim +PluginInstall +qall
}

read -p "Your current setting files (~/.bashrc & ~/.vimrc) will copy with '*.orig' extension in $HOME directory. Are you sure? (y/n) " -n 1;
echo "";
if [[ $REPLY =~ ^[Yy]$ ]]; then
	envSetup;
fi; 
