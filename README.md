# Genev Protocol

Genev is a decentralized lending protocol forked from Morpho Blue, designed for the Kaia network. It provides isolated lending pools and earning native yield on deposited assets.

## Features

- **Isolated Lending Markets**: Each market operates independently with its own risk parameters
- **Oracle Integration**: Support for Orakl price feeds using adapters to be Chainlink-compliant
- **Multi-Asset Support**: Native support for WKAIA and USDT on Kaia network

## Architecture

### Core Components

- **Morpho**: Main lending protocol contract
- **MetaMorpho**: ERC4626 vaults for automated market allocation
- **Interest Rate Models**: Adaptive curve and fixed-rate implementations
- **Oracles**: Price feed integration for asset valuation

### Supported Assets

- **WKAIA**: Wrapped Kaia (0x19Aac5f612f524B754CA7e7c41cbFa2E981A4432)
- **USDT**: Tether USD (0xd077A400968890Eacc75cdc901F0356c943e4fDb)

## Development

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org/) (v18+)
- [Yarn](https://yarnpkg.com/)

### Setup

```bash
# Install dependencies
yarn install

# Install Foundry dependencies
forge install

# Build contracts
yarn build:forge
```

### Local Deployment

```bash
cp .env.example .env

make anvil

# Deploy to local network
make deploy-local
```


