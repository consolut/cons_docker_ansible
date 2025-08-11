# SSH Keys Directory

## ⚠️ SECURITY WARNING
**NEVER commit actual SSH private keys to this repository!**

This directory is for documentation purposes only. Real SSH keys should be:

1. **Mounted at runtime** using Docker volumes
2. **Stored securely** using proper secret management tools
3. **Never included** in the Docker image

## Recommended Usage

### Option 1: Mount SSH keys at runtime
```bash
docker run -v ~/.ssh:/home/ansible/.ssh:ro ansible_docker
```

### Option 2: Use Docker Secrets (Swarm mode)
```bash
echo "YOUR_PRIVATE_KEY" | docker secret create ansible_ssh_key -
docker service create --secret ansible_ssh_key ansible_docker
```

### Option 3: Use environment-specific key management
- **Development**: Use temporary keys generated for testing
- **Production**: Use HashiCorp Vault, AWS Secrets Manager, or similar

## Generate new SSH keys
```bash
ssh-keygen -t ed25519 -f ~/.ssh/ansible_key -C "ansible@example.com"
```

## Security Best Practices
1. Use Ed25519 or RSA (4096 bits minimum) keys
2. Always use passphrases for private keys
3. Rotate keys regularly
4. Use different keys for different environments
5. Implement proper key access controls
6. Monitor key usage and access logs