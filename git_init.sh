#!/bin/bash

SSH_KEY_PATH="$HOME/.ssh/man_rsa_key"
GIT_REPO_PATH="$HOME/Documents/git_repos/man.io"
VENV_PATH="$GIT_REPO_PATH/.venv"

rm -rf "$VENV_PATH"

# Start the ssh-agent and add your ssh-key
echo "Starting ssh-agent..."
eval "$(ssh-agent -s)"

echo "Adding ssh-key..."
ssh-add "$SSH_KEY_PATH"

# Test SSH connection
ssh -T git@github.com 2>&1 | tee "$HOME/tmp/ssh_test.log" | grep -q "successfully authenticated"
if [ $? -eq 0 ]; then
    echo "SSH connection successful."
else
    echo "SSH connection failed. Check /tmp/ssh_test.log for details."
    exit 1
fi

# Pull the latest changes from the main branch
echo "Pulling latest changes from the main branch..."
cd "$GIT_REPO_PATH" || exit
git pull origin main

# Install any required dependencies (Python or Node.js)
echo "Checking for Python virtual environment..."
uv venv
if [ -d "$VENV_PATH" ]; then
    echo "Activating Python virtual environment..."
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        source "$VENV_PATH/Scripts/activate"  # Windows
    else
        source "$VENV_PATH/bin/activate"  # Unix-based systems
    fi

    # Install additional dependencies using uv if needed
    echo "Installing additional Python dependencies using uv..."
    uv run
else
    # Check for Node.js dependencies
    if [ -f "$GIT_REPO_PATH/package.json" ]; then
        echo "Installing frontend dependencies using uv..."
        cd "$GIT_REPO_PATH/frontend" && uv npm install
    fi
fi

# Indicate environment setup is completed
echo "Environment setup completed!"
