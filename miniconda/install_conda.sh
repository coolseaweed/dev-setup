#!/bin/bash


OS="linux" # centos macos windows
CONDA_BASE=$HOME/ENV/miniconda3

if [[ $OS == "linux" ]];then
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh 
    bash Miniconda3-latest-Linux-x86_64.sh -b -u -p $CONDA_BASE
    $CONDA_BASE/bin/conda init
    rm Miniconda3-latest-Linux-x86_64.sh*
fi


