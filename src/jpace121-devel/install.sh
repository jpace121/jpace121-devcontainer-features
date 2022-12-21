#!/bin/bash
set -e

# Helper functions.
debian_install() {
    export DEBIAN_FRONTEND=noninteractive
    apt update -y
    apt install -y tzdata \
                sudo \
                iproute2 \
                emacs-nox \
                vim-nox \
                git \
                openssh-client \
                tmux \
                procps \
                silversearcher-ag
}

fedora_install() {
    dnf upgrade -y
    dnf install -y emacs-nox \
                   vim-minimal \
                   git \
                   tmux \
                   the_silver_searcher\
                   findutils
}

debian_user_setup() {
    if id ${_REMOTE_USER} &>/dev/null; then
        echo '${_REMOTE_USER} found. Moving on.'
    else
        # Set up user.
        useradd -m -G sudo -s /bin/bash ${_REMOTE_USER}
        echo "%sudo  ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/container
        chmod 0440 /etc/sudoers.d/container
        # So we don't get bothered first call to sudo
        su ${_REMOTE_USER} -c "touch /home/${_REMOTE_USER}/.sudo_as_admin_successful"
   fi
}

fedora_user_setup() {
    if id ${_REMOTE_USER} &>/dev/null; then
        echo '${_REMOTE_USER} found. Moving on.'
    else
        # Set up user.
        useradd -m -G wheel -s /bin/bash ${_REMOTE_USER}
        bash -c 'echo "%wheel  ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/container'
        chmod 0440 /etc/sudoers.d/container
        # So we don't get bothered first call to sudo
        su ${_REMOTE_USER} -c "touch /home/${_REMOTE_USER}/.sudo_as_admin_successful"
   fi
}

common_setup() {
    cp vimrc /home/${_REMOTE_USER}/.vimrc
    cp gitconfig /home/${_REMOTE_USER}/.gitconfig
    cp tmux.conf  /home/${_REMOTE_USER}/.tmux.conf
    chown ${_REMOTE_USER}:${_REMOTE_USER} /home/${_REMOTE_USER}/.vimrc /home/${_REMOTE_USER}/.gitconfig /home/${_REMOTE_USER}/.tmux.conf

    git clone --recursive --depth 1 https://github.com/jpace121/evil-ed.git /home/${_REMOTE_USER}/.emacs.d
    chown -R ${_REMOTE_USER}:${_REMOTE_USER} /home/${_REMOTE_USER}/.emacs.d
    echo 'alias emc='\''emacsclient -t --alternate-editor=""'\''' >> /home/${_REMOTE_USER}/.bashrc
    rm -f /home/${_REMOTE_USER}/.emacs

    echo 'TERM=xterm-256color' >> /home/${_REMOTE_USER}/.bashrc
}

# Now run stuff based on our current distro.
. /etc/os-release
if [ "${ID}" = "debian" ]; then
    debian_install
    debian_user_setup
fi
if [ "${ID}" = "fedora" ]; then
    fedora_install
    fedora_user_setup
fi
common_setup


