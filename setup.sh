#!/bin/bash
DAEMON_NAME=junctiond
DAEMON_HOME=$HOME/.junction-testnet
SERVICE_NAME=junctiond-testnet
INSTALLATION_DIR=$(dirname "$(realpath "$0")")
CHAIN_ID='junction'
GENESIS_URL="https://github.com/airchains-network/junction/releases/download/v0.1.0/genesis.json"
PEERS="df2a56a208821492bd3d04dd2e91672657c79325@airchain-testnet-peer.cryptonode.id:27656,aeaf101d54d47f6c99b4755983b64e8504f6132d@airchain-testnet-peer.dashnode.org:28656,47f61921b54a652ca5241e2a7fc4ed8663091e89@airchains-testnet-peer.itrocket.net:19656,04e2fdd6ec8f23729f24245171eaceae5219aa91@airchains-testnet-seed.itrocket.net:19656,2d1ea4833843cc1433e3c44e69e297f357d2d8bd@5.78.118.106:26656"
RPC="https://airchain-testnet-rpc.cryptonode.id:443"
SEEDS="2d1ea4833843cc1433e3c44e69e297f357d2d8bd@5.78.118.106:26656"
DENOM='amf'
REPO=""
BIN_REPO="https://github.com/airchains-network/junction/releases/download/v0.1.0/junctiond"
REPO_DIR="junction"
BRANCH="v0.1.0"
GOPATH=$HOME/go

#Prerequisites
cd ${INSTALLATION_DIR}
if ! grep -q "export GOPATH=" ~/.profile; then
    echo "export GOPATH=$HOME/go" >> ~/.profile
    source ~/.profile
fi
if ! grep -q "export PATH=.*:/usr/local/go/bin" ~/.profile; then
    echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.profile
    source ~/.profile
fi
if ! grep -q "export PATH=.*$GOPATH/bin" ~/.profile; then
    echo "export PATH=$PATH:$GOPATH/bin" >> ~/.profile
    source ~/.profile
fi
if ! grep -q "export DAEMON_NAME=${DAEMON_NAME}" $HOME/.profile; then
    echo "export DAEMON_NAME=${DAEMON_NAME}" >> $HOME/.profile
fi
if ! grep -q "export DAEMON_HOME=${DAEMON_HOME}" $HOME/.profile; then
    echo "export DAEMON_HOME=${DAEMON_HOME}" >> $HOME/.profile
fi
if ! grep -q "export DAEMON_RESTART_AFTER_UPGRADE=false" $HOME/.profile; then
    echo "export DAEMON_RESTART_AFTER_UPGRADE=false" >> $HOME/.profile
fi
if ! grep -q "export DAEMON_ALLOW_DOWNLOAD_BINARIES=true" $HOME/.profile; then
    echo "export DAEMON_ALLOW_DOWNLOAD_BINARIES=true" >> $HOME/.profile
fi
if ! grep -q "export CHAIN_ID=${CHAIN_ID}" $HOME/.profile; then
    echo "export CHAIN_ID=${CHAIN_ID}" >> $HOME/.profile
fi
source $HOME/.profile
##Check and install Go
GO_VERSION=$(go version 2>/dev/null | grep -oP 'go1\.22\.0')
if [ -z "$(echo "$GO_VERSION" | grep -E 'go1\.22\.0')" ]; then
    echo "Go is not installed or not version 1.22.0. Installing Go 1.22.0..."
    wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
    sudo rm -rf $(which go)
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
    rm go1.22.0.linux-amd64.tar.gz
else
    echo "Go version 1.22.0 is already installed."
fi
##Check and install cosmovisor
if ! command -v cosmovisor > /dev/null 2>&1 || ! which cosmovisor &> /dev/null; then
    wget https://github.com/cosmos/cosmos-sdk/releases/download/cosmovisor%2Fv1.5.0/cosmovisor-v1.5.0-linux-amd64.tar.gz
    tar -xvzf cosmovisor-v1.5.0-linux-amd64.tar.gz
    rm cosmovisor-v1.5.0-linux-amd64.tar.gz
    sudo cp cosmovisor /usr/local/bin/cosmovisor
fi
sudo apt -qy install curl git jq lz4 build-essential unzip tar

#Prepare Validator Data
read -p "Enter validator name (leave blank for default 'CryptoNodeID'): " VALIDATOR_KEY_NAME
VALIDATOR_KEY_NAME=${VALIDATOR_KEY_NAME:-"CryptoNodeID"}
echo "Get your identity by following this steps: https://docs.harmony.one/home/network/validators/managing-a-validator/adding-a-validator-logo"
read -p "Enter identity (leave blank for default '4a8bc33cee42de0b23bbccbc84aee10fd0cdfc07'): " INPUT_IDENTITY
INPUT_IDENTITY=${INPUT_IDENTITY:-"4a8bc33cee42de0b23bbccbc84aee10fd0cdfc07"}
read -p "Enter website (leave blank for default 'https://cryptonode.id'): " INPUT_WEBSITE
INPUT_WEBSITE=${INPUT_WEBSITE:-"https://cryptonode.id"}
read -p "Enter your email (leave blank for default 'admin@cryptonode.id'): " INPUT_EMAIL
INPUT_EMAIL=${INPUT_EMAIL:-"admin@cryptonode.id"}
read -p "Enter details (leave blank for default 'Created with CryptoNodeID helper. Crypto Validator Node Education Channel. Join us for more details at https://t.me/CryptoNodeID'): " INPUT_DETAILS
INPUT_DETAILS=${INPUT_DETAILS:-"Created with CryptoNodeID helper. Crypto Validator Node Education Channel. Join us for more details at https://t.me/CryptoNodeID"}

#Display data
echo "DAEMON_NAME=$DAEMON_NAME"
echo "DAEMON_HOME=$DAEMON_HOME"
echo "DAEMON_ALLOW_DOWNLOAD_BINARIES=$DAEMON_ALLOW_DOWNLOAD_BINARIES"
echo "DAEMON_RESTART_AFTER_UPGRADE=$DAEMON_RESTART_AFTER_UPGRADE"
echo "DAEMON_LOG_BUFFER_SIZE=$DAEMON_LOG_BUFFER_SIZE"
echo "Chain id: "${CHAIN_ID}
echo "RPC: "${RPC}
echo "Service name: "${SERVICE_NAME}
echo "======================================================================="
echo "Validator key name: "${VALIDATOR_KEY_NAME}
echo "Identity: "${INPUT_IDENTITY}
echo "Website: "${INPUT_WEBSITE}
echo "Email: "${INPUT_EMAIL}
echo "Details: "${INPUT_DETAILS}

read -p "Press enter to continue or Ctrl+C to cancel"

#Prepare directory
if [ -n "$REPO" ]; then
    rm -rf ${REPO_DIR}
    rm -rf ${DAEMON_HOME}
    #Install daemon
    git clone ${REPO}
    cd ${REPO_DIR}
    git checkout ${BRANCH}
    make install
else
    wget -O ${DAEMON_NAME} ${BIN_REPO}
    chmod +x ${DAEMON_NAME}
fi

if ! grep -q 'export KEYRING_BACKEND=file' ~/.profile; then
    echo "export KEYRING_BACKEND=file" >> ~/.profile
fi
if ! grep -q 'export WALLET='${VALIDATOR_KEY_NAME} ~/.profile; then
    echo "export WALLET=${VALIDATOR_KEY_NAME}" >> ~/.profile
fi
source ~/.profile

mkdir -p ${DAEMON_HOME}/cosmovisor/genesis/bin
mkdir -p ${DAEMON_HOME}/cosmovisor/upgrades
cp ${DAEMON_NAME} ${DAEMON_HOME}/cosmovisor/genesis/bin/

sudo ln -s ${DAEMON_HOME}/cosmovisor/genesis ${DAEMON_HOME}/cosmovisor/current -f
sudo ln -s ${DAEMON_HOME}/cosmovisor/current/bin/${DAEMON_NAME} /usr/local/bin/${DAEMON_NAME} -f

mkdir -p ${DAEMON_HOME}/cosmovisor/upgrades/$(${DAEMON_NAME} --home ${DAEMON_HOME} version)/bin/
cp $(which ${DAEMON_NAME}) ${DAEMON_HOME}/cosmovisor/upgrades/$(${DAEMON_NAME} --home ${DAEMON_HOME} version)/bin/${DAEMON_NAME}

echo "${DAEMON_NAME} version: "$(${DAEMON_NAME} --home ${DAEMON_HOME} version)
read -p "Press enter to continue or Ctrl+C to cancel"

read -p "Do you want to recover wallet? [y/N]: " RECOVER
RECOVER=$(echo "${RECOVER}" | tr '[:upper:]' '[:lower:]')
if [[ "${RECOVER}" == "y" || "${RECOVER}" == "yes" ]]; then
    ${DAEMON_NAME} keys add ${VALIDATOR_KEY_NAME} --recover
else
    ${DAEMON_NAME} keys add ${VALIDATOR_KEY_NAME}
fi
read -p "Save you information and Press enter to continue or Ctrl+C to cancel"
${DAEMON_NAME} config chain-id ${CHAIN_ID}
${DAEMON_NAME} config node ${RPC}
${DAEMON_NAME} init ${VALIDATOR_KEY_NAME} --chain-id=${CHAIN_ID}
${DAEMON_NAME} keys list

#Set custom ports
read -p "Do you want to use custom port number prefix (y/N)? " use_custom_port
if [[ "$use_custom_port" =~ ^[Yy](es)?$ ]]; then
    read -p "Enter port number prefix (max 2 digits, not exceeding 50): " port_prefix
    while [[ "$port_prefix" =~ [^0-9] || ${#port_prefix} -gt 2 || $port_prefix -gt 50 ]]; do
        read -p "Invalid input, enter port number prefix (max 2 digits, not exceeding 50): " port_prefix
    done
    ${DAEMON_NAME} config node tcp://localhost:${port_prefix}657
    sed -i.bak -e "s%:1317%:${port_prefix}317%g; s%:8080%:${port_prefix}080%g; s%:9090%:${port_prefix}090%g; s%:9091%:${port_prefix}091%g; s%:8545%:${port_prefix}545%g; s%:8546%:${port_prefix}546%g; s%:6065%:${port_prefix}065%g" ${DAEMON_HOME}/config/app.toml
    sed -i.bak -e "s%:26658%:${port_prefix}658%g; s%:26657%:${port_prefix}657%g; s%:6060%:${port_prefix}060%g; s%:26656%:${port_prefix}656%g; s%:26660%:${port_prefix}660%g" ${DAEMON_HOME}/config/config.toml
    ${DAEMON_NAME} config node tcp://localhost:${port_prefix}657
fi

#Set configs
wget ${GENESIS_URL} -O ${DAEMON_HOME}/config/genesis.json
sed -i.bak \
    -e "/^[[:space:]]*seeds =/ s/=.*/= \"${SEEDS}\"/" \
    -e "s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"${PEERS}\"/" \
    ${DAEMON_HOME}/config/config.toml

sed -i 's/minimum-gas-prices *=.*/minimum-gas-prices = "0.025'$DENOM'"/' ${DAEMON_HOME}/config/app.toml
sed -i \
  -e 's|^[[:space:]]*pruning *=.*|pruning = "custom"|' \
  -e 's|^[[:space:]]*pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^[[:space:]]*pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^[[:space:]]*pruning-interval *=.*|pruning-interval = "10"|' \
  ${DAEMON_HOME}/config/app.toml
indexer="null" && \
sed -i -e "s/^[[:space:]]*indexer *=.*/indexer = \"$indexer\"/" ${DAEMON_HOME}/config/config.toml

# Helper scripts
cd ${INSTALLATION_DIR}
rm -rf list_keys.sh check_balance.sh create_validator.sh unjail_validator.sh check_validator.sh start_side.sh check_log.sh

echo "${DAEMON_NAME} keys list" > list_keys.sh
chmod ug+x list_keys.sh

echo "${DAEMON_NAME} q bank balances \$(${DAEMON_NAME} keys show $VALIDATOR_KEY_NAME -a)" > check_balance.sh
chmod ug+x check_balance.sh

tee claim_commission.sh > /dev/null <<EOF
#!/bin/bash
${DAEMON_NAME} tx distribution withdraw-all-rewards \\
  --from=$VALIDATOR_KEY_NAME \\
  --commission \\
  --chain-id="$CHAIN_ID" \\
  --fees="1000${DENOM}" \\
  --yes
EOF
chmod ug+x claim_commission.sh

tee delegate.sh > /dev/null <<EOF
#!/bin/bash
${DAEMON_NAME} q bank balances \$(${DAEMON_NAME} keys show $VALIDATOR_KEY_NAME -a)

while true; do
    read -p "Enter the amount to delegate (in $DENOM, not 0): " amount
    if [[ ! \${amount} =~ ^[0-9]+(\.[0-9]*)?$ ]] || (( 10#\${amount} == 0 )); then
        echo "Invalid amount, please try again" >&2
    else
        ${DAEMON_NAME} tx staking delegate \$(${DAEMON_NAME} keys show $VALIDATOR_KEY_NAME --bech val -a) \${amount}${DENOM} \\
        --from=$VALIDATOR_KEY_NAME \\
        --chain-id="$CHAIN_ID" \\
        --gas="200000" \\
        --gas-prices="0.025${DENOM}"
    fi
done
EOF
chmod ug+x delegate.sh

tee validator.json > /dev/null <<EOF
{
    "pubkey": $(${DAEMON_NAME} comet show-validator),
    "amount": "1000000${DENOM}",
    "moniker": "$VALIDATOR_KEY_NAME",
    "identity": "$INPUT_IDENTITY",
    "website": "$INPUT_WEBSITE",
    "security": "$INPUT_EMAIL",
    "details": "$INPUT_DETAILS",
    "commission-rate": "0.1",
    "commission-max-rate": "0.2",
    "commission-max-change-rate": "0.01",
    "min-self-delegation": "1"
}
EOF
tee create_validator.sh > /dev/null <<EOF
#!/bin/bash
${DAEMON_NAME} tx staking create-validator ./validator.json \
    --from=${VALIDATOR_KEY_NAME} \
    --chain-id=${CHAIN_ID} \
    --fees=500${DENOM}
EOF
chmod +x create_validator.sh

tee unjail_validator.sh > /dev/null <<EOF
#!/bin/bash
${DAEMON_NAME} tx slashing unjail \\
 --from=$VALIDATOR_KEY_NAME \\
 --chain-id="$CHAIN_ID" \\
 --gas="300000" \\
 --gas-prices="0.025${DENOM}"
EOF
chmod ug+x unjail_validator.sh

tee check_validator.sh > /dev/null <<EOF
#!/bin/bash
${DAEMON_NAME} query tendermint-validator-set | grep "\$(${DAEMON_NAME} tendermint show-address)"
EOF
chmod ug+x check_validator.sh

tee start_${DAEMON_NAME}.sh > /dev/null <<EOF
sudo systemctl daemon-reload
sudo systemctl enable ${SERVICE_NAME}
sudo systemctl restart ${SERVICE_NAME}
EOF
chmod ug+x start_${DAEMON_NAME}.sh

tee stop_${DAEMON_NAME}.sh > /dev/null <<EOF
sudo systemctl stop ${SERVICE_NAME}
EOF
chmod ug+x stop_${DAEMON_NAME}.sh

tee check_log.sh > /dev/null <<EOF
sudo journalctl -u ${SERVICE_NAME} -f
EOF
chmod ug+x check_log.sh

sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null <<EOF
[Unit]
Description=${DAEMON_NAME} daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start --home=${DAEMON_HOME}
Restart=always
RestartSec=3
LimitNOFILE=infinity

Environment="DAEMON_NAME=${DAEMON_NAME}"
Environment="DAEMON_HOME=${DAEMON_HOME}"
Environment="DAEMON_RESTART_AFTER_UPGRADE=false"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
read -p "Do you want to enable the ${DAEMON_NAME} service? (y/N): " ENABLE_SERVICE
if [[ "$ENABLE_SERVICE" =~ ^[Yy](es)?$ ]]; then
    sudo systemctl enable ${SERVICE_NAME}.service
else
    echo "Skipping enabling ${SERVICE_NAME} service."
fi
