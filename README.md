# Ansible Docker Container

This Docker image is based on the latest minimal Ubuntu version and is prepared for use with Ansible.
It includes various tools and configurations to facilitate working with Ansible.

## Table of Contents

- [Build](#build)
- [Usage](#usage)
- [Dockerfile Contents](#dockerfile-contents)
- [Configuration](#configuration)
- [Licenses](#licenses)

## Build

### Single Architecture Build
To build the Docker image for your current architecture:

```bash
docker build -t ansible_docker .
```

### Multi-Architecture Build (ARM64 + AMD64)
To build for both ARM and x86 platforms using Docker Buildx:

```bash
# Create and use a new builder instance
docker buildx create --name multiarch --use

# Build and push multi-architecture image
docker buildx build --platform linux/amd64,linux/arm64 \
  -t rotecodefraktion/ansible_docker:secure \
  -t rotecodefraktion/ansible_docker:latest \
  --push .

# Optional: Remove builder when done
docker buildx rm multiarch
```

**Note:** Currently the image on Docker Hub is ARM64 only. Multi-architecture support coming soon.

## Usage

### Security Notice 🔒
The `:secure` tag includes comprehensive security improvements including:
- Fixed Ubuntu 24.04 LTS version
- Removed default SSH keys (mount at runtime)
- Limited sudo access
- Enabled SSH host key verification
- Pinned dependency versions (CVE-2024-26130 fixed)

### Quickstart from Docker Hub

**Secure version (recommended):**
```bash
docker run -it -d --name ansible_docker rotecodefraktion/ansible_docker:secure
```

**With persistent storage and SSH keys:**
```bash
docker run -v /tmp/docker_ansible:/install/ansible \
           -v ~/.ssh:/home/ansible/.ssh:ro \
           -it -d --name ansible_docker \
           rotecodefraktion/ansible_docker:secure
```

You can create a fresh ssh key-pair with ssh-keygen inside the container or you can use your own ssh key from outside the container. To copy your own ssh-key to the container:

```bash
docker cp ~/.ssh/id_rsa ansible_docker:/home/ansible/.ssh/
docker exec -u 0 -it ansible_docker chown ansible:ansible /home/ansible/.ssh/id_rsa
docker exec -it ansible_docker /bin/zsh
```

### Build your on image

```bash
git clone ttps://github.com/davidkrcek/docker_ansible.git
docker build -t ansible_docker .
docker run -it -d --name ansible_docker ansible_docker
```

The container will start with the zsh shell, and you will be in the working directory for Ansible.

## Dockerfile Contents

The Dockerfile installs the following packages and configures the environment:

- Base Image: Latest version of Ubuntu.

  - gcc
  - python3 python3-pip python3-venv
  - wget curl
  - openssh-client
  - vim
  - zsh
  - ohmyzsh
  - git
  - sudo

- Environment Variables: Configures user and directories for Ansible.
- User Creation: Creates a new user ansible and configures its environment.
- Zsh and Oh My Zsh: Installs and configures zsh and Oh My Zsh with plugins and themes.
- Python and Ansible: Installs Python3, pip, and Ansible within a Python virtual environment.
- SSH Configuration: Copies SSH keys and configurations to the home directory of the Ansible user.

## Configuration

To customize the configuration, modify the corresponding environment variables in the Dockerfile.

- ANSIBLE_USER: ansible or any other user inside the container which connects to the satellites
- ANSIBLE_USER_UID: 1002 or any other id, helps to read/write attached filesystems to the container
- ARG ANSIBLE_HOME: /home/ansible
- ANSIBLE_WORKDIR: attached directory from host to container

- Copy all ssh keys (private keys) from ./config/ssh_keys to ANSIBLE_HOME/.ssh/

  **Please use a allways a secret when generating private keys**

- If you build the docker image behind ZScaler or similar you can upload the necessary certificates to ./conifg/cacerts
  to avoid git certifcates errors

## Licenses

This project uses the following licenses:

- GPL-3.0 license
- Ubuntu: Ubuntu License (https://hub.docker.com/_/ubuntu)
- Zsh (https://github.com/zsh-users/zsh/tree/master)
- Oh My Zsh: (https://github.com/ohmyzsh/ohmyzsh)

  For more information on the licenses of the installed packages, please consult the respective documentation.
