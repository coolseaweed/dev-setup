FROM ubuntu:20.04

ARG USERNAME=docker
ARG USER_UID=1000
ARG USER_GID=$USER_UID


# Create the user
# TODO: bugfix for group already exist case
# [Optional] Add group if not exist 
# RUN groupadd --gid $USER_GID $USERNAME 
RUN useradd --uid $USER_UID --gid $USER_GID -m $USERNAME 

# [Optional] Add sudo support. Omit if you don't need to install software after connecting.
RUN apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# ********************************************************
# * Anything else you want to do like clean up goes here *
# ********************************************************
# Install basic packages
RUN apt-get update && apt-get install -y \
    xz-utils git 

USER $USERNAME

SHELL ["/bin/bash", "-c"]