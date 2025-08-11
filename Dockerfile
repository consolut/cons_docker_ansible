# Ubuntu 24.04 LTS (Noble Numbat) - Fixed version for security
FROM ubuntu:24.04

# Environments
ARG ANSIBLE_USER="ansible"
ARG ANSIBLE_USER_UID="1002"
ARG ANSIBLE_HOME="/home/ansible"
ARG ANSIBLE_WORKDIR="/install/ansible"
ENV VENV_NAME="${ANSIBLE_HOME}/venv"

# Update the repositories and refresh system
RUN apt-get update

# Install zsh and git
RUN apt-get install zsh git sudo -y 
# Install Pyhton3 and Python3-pip and other tools
# and clean up all
RUN apt-get install -y gcc python3 python3-pip python3-venv ; \
    apt-get install -y wget curl openssh-client vim ; \
    apt-get install -y locales-all
RUN apt-get clean all

# Add local certificates for zscaler & Co. support later in git
RUN apt-get install apt-transport-https ca-certificates -y 
COPY config/cacerts /tmp/cacerts
RUN mv /tmp/cacerts/* /usr/local/share/ca-certificates/
RUN update-ca-certificates 

# create ansible user 
RUN useradd -m -s /bin/zsh -u "${ANSIBLE_USER_UID}" -G sudo "${ANSIBLE_USER}"
# Limited sudo access - only for specific ansible commands
RUN echo 'ansible ALL=(ALL) NOPASSWD: /usr/bin/ansible-playbook, /usr/bin/ansible, /usr/bin/ansible-vault' >> /etc/sudoers.d/ansible
RUN mkdir -p "${ANSIBLE_HOME}"/.ssh && mkdir -p "${ANSIBLE_WORKDIR}"
RUN chown -R ansible:ansible "${ANSIBLE_HOME}"/.ssh
# SSH config with improved security - StrictHostKeyChecking enabled by default
# Users can override for specific hosts if needed
RUN echo "Host *\n\tStrictHostKeyChecking accept-new\n\tHashKnownHosts yes\n" >> "${ANSIBLE_HOME}"/.ssh/config

#switch to ansible user and install and configure zsh/ohmayzsh
USER ansible
SHELL ["/bin/bash", "-c"]

RUN python3 -m venv "${VENV_NAME}"

RUN source "${VENV_NAME}"/bin/activate 
ENV PATH="${VENV_NAME}/bin:/home/ansible/.local/bin:${PATH}"
ENV ZSH="/home/ansible/.oh-my-zsh"

# Install Oh-My-Zsh with specific commit for stability
RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "${ZSH}" && \
    git -C "${ZSH}" checkout 4c82a2eedf0c43d47601ffa8b0303ed1326fab8f

# Install ZSH plugins with pinned versions
RUN git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${ZSH}/custom/plugins/zsh-autosuggestions" && \
    git -C "${ZSH}/custom/plugins/zsh-autosuggestions" checkout v0.7.0 && \
    git clone --depth=1 https://github.com/zsh-users/zsh-completions "${ZSH}/custom/plugins/zsh-completions" && \
    git -C "${ZSH}/custom/plugins/zsh-completions" checkout 0.35.0 && \
    git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search.git "${ZSH}/custom/plugins/zsh-history-substring-search" && \
    git -C "${ZSH}/custom/plugins/zsh-history-substring-search" checkout v1.1.0 && \
    git clone --depth=1 https://github.com/denysdovhan/spaceship-prompt.git "${ZSH}/custom/themes/spaceship-prompt" && \
    git -C "${ZSH}/custom/themes/spaceship-prompt" checkout v4.15.0 && \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH}/custom/plugins/zsh-syntax-highlighting" && \
    git -C "${ZSH}/custom/plugins/zsh-syntax-highlighting" checkout 0.8.0 && \
    git clone --depth=1 --branch v0.44.0 https://github.com/junegunn/fzf.git "/home/ansible/.fzf" && \
    /home/ansible/.fzf/install --no-bash --no-fish --no-update-rc


# Copy requirements file for dependency management
COPY --chown=ansible:ansible requirements.txt /tmp/requirements.txt

# Upgrade pip to specific version and install dependencies
RUN pip3 install --upgrade pip==23.3.2 && \
    pip3 install -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# copy only ZSH configuration into image
# SSH keys should be mounted at runtime, not built into image
COPY --chown=ansible:ansible ./config/zsh/.zshrc ${ANSIBLE_HOME}/.zshrc

# Create SSH directory with proper permissions
RUN mkdir -p ${ANSIBLE_HOME}/.ssh && \
    chmod 700 ${ANSIBLE_HOME}/.ssh


# Set the default shell to zsh
CMD ["/bin/zsh"]    

# Set workdir to your ansible direcotry
WORKDIR "${ANSIBLE_WORKDIR}"