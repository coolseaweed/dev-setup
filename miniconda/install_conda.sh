#!/bin/bash


OS="linux" # centos macos windows
PREFIX=$HOME/ENV/miniconda3

if [[ $OS == "linux" ]];then
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -u -p $PREFIX && \
    conda init 
    rm Miniconda3-latest-Linux-x86_64.sh*
fi


