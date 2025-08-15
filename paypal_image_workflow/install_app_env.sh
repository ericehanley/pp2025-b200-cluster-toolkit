#!/bin/bash
set -euxo pipefail

echo "--- Starting Application Environment Installation ---"

# 1. Install System Dependencies (Python 3.11, build tools)
echo "Installing system dependencies..."
add-apt-repository -y ppa:deadsnakes/ppa
apt-get update
apt-get install -y python3.11 python3.11-venv python3.11-dev build-essential git

# 2. Create a system-wide Virtual Environment
echo "Creating Python virtual environment in /opt/symphony-env..."
python3.11 -m venv /opt/symphony-env

# 3. Create an activation script for all users
echo "Configuring environment to be active by default..."
cat <<EOF > /etc/profile.d/symphony-env.sh
#!/bin/bash
# Activate the Symphony Python environment
source /opt/symphony-env/bin/activate
EOF
chmod +x /etc/profile.d/symphony-env.sh

# 4. Activate the environment and install packages
echo "Activating environment and installing Python packages..."
source /opt/symphony-env/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install PyTorch 2.7 for CUDA 12.8 from NVIDIA's index
echo "Installing PyTorch for CUDA 12.8..."
pip install torch==2.7.0 --extra-index-url https://pypi.ngc.nvidia.com

# Install packages from requirements.txt (torchvision is now here)
echo "Installing packages from requirements.txt..."
pip install --no-cache-dir -r /var/tmp/requirements.txt

# Final check
echo "Verifying installations..."
pip list

echo "--- Application Environment Installation Complete! ---"