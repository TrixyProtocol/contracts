# Trixy Protocol - Cadence Contracts

Cadence smart contracts for the Trixy prediction market protocol on Flow blockchain.

## Overview

Trixy is a decentralized prediction market platform that combines binary betting markets with DeFi yield protocols. Users can place bets on prediction markets while their staked assets earn yield through integration with protocols like Ankr, Increment, and Figment.

## Architecture

### Core Contracts

#### `TrixyTypes.cdc`
Defines common types and data structures used across the protocol:
- **Enums**: `MarketStatus`, `ProtocolType`
- **Structs**: 
  - `ProtocolStats` - Statistics for staking protocols
  - `UserPosition` - User's position in a market
  - `MarketInfo` - Market metadata
  - `BinaryPosition` - Binary prediction market position (YES/NO)
  - `PredictionMarketInfo` - Prediction market details

#### `TrixyEvents.cdc`
Event definitions for the protocol:
- `MarketCreated` - Emitted when a new market is created
- `BetPlaced` - Emitted when a bet is placed
- `MarketResolved` - Emitted when a market is resolved
- `WinningsClaimed` - Emitted when winnings are claimed
- `YieldDeposited` - Emitted when funds are deposited to yield protocol
- `YieldWithdrawn` - Emitted when funds are withdrawn from yield protocol

#### `Market.cdc`
Staking-based prediction market implementation:
- Multi-option markets with staking protocol integration
- Supports Ankr, Increment, and Figment protocols
- APY-based yield generation
- Winner-takes-all with yield sharing

#### `PredictionMarket.cdc`
Binary (YES/NO) prediction market implementation:
- Simple binary outcome markets
- Integrated yield protocol support
- Proportional payout system
- Yield distribution to both winners and losers

#### `TrixyProtocol.cdc`
Main protocol contract that manages:
- Market creation and lifecycle
- Market registry and lookup
- Admin functions
- Integration with both Market and PredictionMarket types

### Adapters

Protocol adapters implement `IStakingProtocol` interface:
- `AnkrAdapter.cdc` - Ankr staking integration
- `IncrementAdapter.cdc` - Increment protocol integration
- `FigmentAdapter.cdc` - Figment staking integration

### Interfaces

#### `IStakingProtocol.cdc`
Standard interface for staking protocol adapters:
- `deposit()` - Deposit funds to earn yield
- `withdraw()` - Withdraw funds
- `getAPY()` - Get current APY
- `getBalance()` - Get deposited balance

## Deployed Contracts

### Flow Testnet
- **Account**: `0xe4a8713903104ee5`
- **Contracts**:
  - `TrixyTypes`
  - `TrixyEvents`
  - `IStakingProtocol`
  - `AnkrAdapter`
  - `IncrementAdapter`
  - `FigmentAdapter`
  - `Market`
  - `TrixyProtocol`

## Scripts

Query scripts for reading blockchain state:

- `get_market_info.cdc` - Get detailed market information
- `get_protocol_apy.cdc` - Get APY for a specific protocol
- `get_protocol_apys.cdc` - Get APYs for all protocols in a market
- `get_user_position.cdc` - Get user's position in a market
- `get_leaderboard.cdc` - Get platform leaderboard
- `get_market_ids.cdc` - List all market IDs (currently disabled)

## Transactions

### User Transactions

- `create_staking_market.cdc` - Create a new staking-based market
- `place_bet.cdc` - Place a bet on a market option
- `claim_winnings.cdc` - Claim winnings from a resolved market
- `resolve_market.cdc` - Resolve a market (admin/creator only)

### Admin Transactions

- `admin/remove_market_contract.cdc` - Remove a market from the protocol

## Usage

### Prerequisites

```bash
# Install Flow CLI
brew install flow-cli

# Verify installation
flow version
```

### Configuration

The project uses `flow.json` for network and account configuration:
- Testnet contracts deployed to `0xe4a8713903104ee5`
- Multiple test accounts configured
- Dependencies on Flow standard contracts (FungibleToken, FlowToken, etc.)

### Creating a Market

```bash
flow transactions send transactions/create_staking_market.cdc \
  "Will ETH reach $5000 in 2025?" \
  1735689600 \
  '["YES", "NO"]' \
  "increment" \
  --network testnet \
  --signer trixy-latest-account
```

### Placing a Bet

```bash
flow transactions send transactions/place_bet.cdc \
  0xe4a8713903104ee5 \
  0 \
  "YES" \
  10.0 \
  --network testnet \
  --signer trixy-fresh-account
```

### Querying Market Info

```bash
flow scripts execute scripts/get_market_info.cdc \
  0xe4a8713903104ee5 \
  0 \
  --network testnet
```

## Development

### Linting

Check code for errors:

```bash
flow cadence lint contracts/**/*.cdc scripts/*.cdc transactions/*.cdc
```

### Testing

Test contracts are in the `tests/` directory:
- `unit_tests.cdc` - Unit tests
- `prediction_market_test.cdc` - Prediction market tests
- `HeistProtocol_test.cdc` - Legacy protocol tests

### Project Structure

```
cadence/
├── contracts/
│   ├── core/              # Core protocol contracts
│   │   ├── TrixyTypes.cdc
│   │   ├── TrixyEvents.cdc
│   │   ├── Market.cdc
│   │   └── PredictionMarket.cdc
│   ├── adapters/          # Protocol adapters
│   │   ├── AnkrAdapter.cdc
│   │   ├── IncrementAdapter.cdc
│   │   └── FigmentAdapter.cdc
│   ├── interfaces/        # Contract interfaces
│   │   └── IStakingProtocol.cdc
│   └── TrixyProtocol.cdc  # Main protocol contract
├── scripts/               # Query scripts
├── transactions/          # Transaction templates
├── tests/                 # Test contracts
└── flow.json              # Flow configuration
```

## Key Features

### Binary Prediction Markets
- Simple YES/NO outcomes
- Integrated yield generation during market duration
- Proportional payout based on winning side
- Both winners and losers receive yield share

### Staking-Based Markets
- Multiple outcome options (up to 10)
- Protocol competition (Ankr, Increment, Figment)
- APY-based yield tracking
- Winner-takes-all with yield distribution

### Yield Integration
- Automated yield protocol deposits
- Real-time APY tracking
- Yield accumulation during market lifetime
- Fair yield distribution on resolution

## Integration with Backend

The backend indexer monitors these contracts:
- Indexes all events (MarketCreated, BetPlaced, etc.)
- Stores data in PostgreSQL for fast queries
- Provides REST API for frontend

See `backend` and `indexer` for implementation details.

## License

MIT
