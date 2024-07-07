#!/bin/bash

print_ascii() {
    echo "  ___       _    _                         "
    echo " / _ \     | |  | |                        "
    echo "| | | |_  _| |__| | __ ___      ___ __ ___ "
    echo "| | | \ \/ /  __  |/ _\` \ \ /\ / / '__/ _ \\"
    echo "| |_| |>  <| |  | | (_| |\ V  V /| | |  __/"
    echo " \___//_/\_\_|  |_|\__,_| \_/\_/ |_|  \___|"
    echo "                                           "
}

echo "===================================="
print_ascii
echo "Welcome to the Fuel Core Setup Script"
echo "===================================="

# Update package lists and upgrade all installed packages
sudo apt-get update -y && sudo apt-get upgrade -y
echo "Installing necessary tools..."

# Install git
check_git() {
    if command -v git &> /dev/null; then
        git_version=$(git --version | head -n 1)
        echo "git is installed: $git_version"
    else
        echo "git is not installed"
        install_git
    fi
}

install_git() {
    echo "Installing git..."
    sudo apt-get install git -y
}

check_git

# Install wget
check_wget() {
    if command -v wget &> /dev/null; then
        wget_version=$(wget --version | head -n 1)
        echo "wget is installed: $wget_version"
    else
        echo "wget is not installed"
        install_wget
    fi
}

install_wget() {
    echo "Installing wget..."
    sudo apt-get install wget -y
}

check_wget

# Install curl
check_curl() {
    if command -v curl &> /dev/null; then
        curl_version=$(curl --version | head -n 1)
        echo "curl is installed: $curl_version"
    else
        echo "curl is not installed"
        install_curl
    fi
}

install_curl() {
    echo "Installing curl..."
    sudo apt-get install curl -y
}

check_curl

# Install rust
check_rustc() {
    if command -v rustc &> /dev/null; then
        rustc_version=$(rustc --version | head -n 1)
        echo "rustc is installed: $rustc_version"
    else
        echo "rustc is not installed."
        install_rustc
    fi
}

install_rustc() {
    echo "Installing rustc..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs/ | sh -s -- -y
    source $HOME/.cargo/env
}

check_rustc

# Install tmux
check_tmux() {
    if command -v tmux &> /dev/null; then
        tmux_version=$(tmux --version | head -n 1)
        echo "tmux is installed: $tmux_version"
    else
        echo "tmux is not installed"
        install_tmux
    fi
}

install_tmux() {
    echo "Installing tmux..."
    sudo apt-get install tmux -y
}

check_tmux

# Install fuel
curl https://install.fuel.network | sh
source $HOME/.bashrc
export PATH="$HOME/.fuelup/bin:$PATH"

fuelup toolchain install latest
fuelup self update
fuelup toolchain install nightly
fuelup default nightly
fuelup show
fuelup default

git clone https://github.com/FuelLabs/chain-configuration chain-configuration
mkdir -p ~/.fuel-sepolia-testnet
cp -r chain-configuration/ignition/* ~/.fuel-sepolia-testnet/

fuelup toolchain install testnet
fuelup default testnet

echo "Now we're going to generate a new Peering Key. Make sure to save them."
fuel-core-keygen new --key-type peering > secret.txt
cat secret.txt
echo "Your keys have been saved to secret.txt."
echo "Please save them securely and press Enter after you have done so."
read -p "If you saved your secret key, press Enter to continue..." enter_key
secret_value=$(jq -r '.secret' secret.txt)

read -p "Enter node name: " nodeName
echo 
# reo  -p "Enter secret key: " secret
echo 
read -p "Enter Sepolia RPC: " RPC
echo 

cat <<EOT > /tmp/fuel_core_command.sh
#!/bin/bash
fuel-core run \\
      --service-name=${nodeName} \\
      --keypair $secret_value \\
      --relayer $RPC  \\
      --ip=0.0.0.0 --port=5333 --peering-port=40453 \\
      --db-path ~/.fuel-sepolia-testnet \\
      --snapshot ~/.fuel-sepolia-testnet \\
      --utxo-validation --poa-instant=false --enable-p2p \\
      --reserved-nodes=/dns4/p2p-testnet.fuel.network/tcp/30333/p2p/16Uiu2HAmDxoChB7AheKNvCVpD4PHJwuDGn8rifMBEHmEynGHvHrf \\
      --sync-header-batch-size=100 \\
      --enable-relayer \\
      --relayer-v2-listening-contracts=0x01855B78C1f8868DE70e84507ec735983bf262dA \\
      --relayer-da-deploy-height=5827607 \\
      --relayer-log-page-size=500 \\
      --sync-block-stream-buffer-size=30
EOT

# Make the script executable
chmod +x /tmp/fuel_core_command.sh

# Start a new tmux session and run the script
SESSION_NAME="my_tmux_session"
tmux new-session -d -s $SESSION_NAME "/tmp/fuel_core_command.sh"

# Attach to the tmux session
tmux attach-session -t $SESSION_NAME

