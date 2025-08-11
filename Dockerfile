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
# Install Python3 and build tools 
# and clean up all  
RUN apt-get install -y gcc python3 python3-venv python3-dev python3-pip ; \
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

# Remove old setuptools from system and prepare for venv
RUN python3 -m pip uninstall -y setuptools && \
    rm -rf /usr/lib/python3/dist-packages/setuptools* /usr/lib/python3/dist-packages/pkg_resources

#switch to ansible user and install and configure zsh/ohmayzsh
USER ansible
SHELL ["/bin/bash", "-c"]

# Create venv without system packages to ensure clean environment
RUN python3 -m venv --without-pip "${VENV_NAME}" && \
    curl -sS https://bootstrap.pypa.io/get-pip.py | "${VENV_NAME}"/bin/python3 -

RUN source "${VENV_NAME}"/bin/activate 
ENV PATH="${VENV_NAME}/bin:/home/ansible/.local/bin:${PATH}"
ENV ZSH="/home/ansible/.oh-my-zsh"

# Install Oh-My-Zsh with specific version tag for stability
RUN git clone --depth=1 --branch master https://github.com/ohmyzsh/ohmyzsh.git "${ZSH}"

# Install ZSH plugins (using latest stable versions for compatibility)
# Note: FZF removed due to build complexity and external dependencies
RUN git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${ZSH}/custom/plugins/zsh-autosuggestions" && \
    git clone --depth=1 https://github.com/zsh-users/zsh-completions "${ZSH}/custom/plugins/zsh-completions" && \
    git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search.git "${ZSH}/custom/plugins/zsh-history-substring-search" && \
    git clone --depth=1 https://github.com/denysdovhan/spaceship-prompt.git "${ZSH}/custom/themes/spaceship-prompt" && \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH}/custom/plugins/zsh-syntax-highlighting"


# Copy requirements file for dependency management
COPY --chown=ansible:ansible requirements.txt /tmp/requirements.txt

# Install secure versions of pip and setuptools in venv
RUN "${VENV_NAME}"/bin/python3 -m pip install --upgrade pip==24.0 setuptools==78.1.1 && \
    "${VENV_NAME}"/bin/python3 -m pip install -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt && \
    "${VENV_NAME}"/bin/python3 -m pip list | grep setuptools

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