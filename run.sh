#!/bin/bash
set -e	
set -o pipefail

DOTFILES=$(realpath ./dot_files)



cd "$(dirname "${BASH_SOURCE}")";


function envSetup() {

    [ -f ~/.bashrc] && cp ~/.bashrc ~/.bashrc.orig
    [ -f ~/.vimrc ] && cp ~/.vimrc ~/.vimrc.orig
    cp ./dot_files/.bashrc ./dot_files/.vimrc ~/;

    [ -d ~/.vim/bundle ] && rm -rf ~/.vim/bundle
    git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    vim +PluginInstall +qall


    # Setup skhd & yabai
    echo "Symlinking dotfiles"
    ln -s $DOTFILES/skhdrc.symlink $HOME/.skhdrc


}

read -p "Your current setting files (~/.bashrc & ~/.vimrc) will copy with '*.orig' extension in $HOME directory. Are you sure? (y/n) " -n 1;
echo "";
if [[ $REPLY =~ ^[Yy]$ ]]; then
	envSetup;
fi; 



