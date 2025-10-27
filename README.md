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

### Helpers

#### `PriceOracle.cdc`
Price oracle and APY calculation contract:
- Real-time FLOW/USD price tracking
- APY calculation for staking protocols (Ankr, Increment, Figment)
- Dynamic APY adjustment based on FLOW price
- Yield projection and payout calculations
- Admin-controlled price updates (updated by cron service every 5 minutes)
- Protocol comparison and best APY finder

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
  - `PriceOracle` - Deployed at `0xe3f7e4d39675d8d3`

## Scripts

Query scripts for reading blockchain state:

- `get_market_info.cdc` - Get detailed market information
- `get_protocol_apy.cdc` - Get APY for a specific protocol
- `get_protocol_apys.cdc` - Get APYs for all protocols in a market
- `get_user_position.cdc` - Get user's position in a market
- `get_leaderboard.cdc` - Get platform leaderboard
- `get_market_ids.cdc` - List all market IDs (currently disabled)

### Price Oracle Scripts

- `get_flow_price.cdc` - Get current FLOW/USD price
- `get_all_apys.cdc` - Get APYs for all staking protocols
- `get_best_protocol.cdc` - Get protocol with highest APY

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
│   ├── helpers/           # Helper contracts
│   │   └── PriceOracle.cdc
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

## FlowActions Integration

### Current Status

**Trixy Protocol now integrates FlowActions on testnet!** ✅

The `Market.cdc` contract uses FlowActions `Source` and `Sink` connectors for composable DeFi operations:
- **`FungibleTokenConnectors.VaultSource`** - Withdraws yield from vaults
- **`FungibleTokenConnectors.VaultSink`** - Deposits funds to yield protocols

The protocol also maintains custom adapters for reference:
- `AnkrAdapter.cdc` - Ankr staking
- `IncrementAdapter.cdc` - Increment protocol  
- `FigmentAdapter.cdc` - Figment staking

### How It Works

Markets use FlowActions connectors for yield vault operations:

1. **Deposit Flow** (`depositToYieldProtocol`):
   ```cadence
   // Use FlowActions Sink to deposit
   if let sink = self.yieldVaultSink {
       sink.depositCapacity(from: &funds)
   }
   ```

2. **Withdrawal Flow** (`withdrawAllYield`):
   ```cadence
   // Use FlowActions Source to withdraw
   if let source = self.yieldVaultSource {
       withdrawn <- source.withdrawAvailable(maxAmount: balance)
   }
   ```

3. **Setup** - Connectors are configured after market creation:
   ```bash
   flow transactions send transactions/setup_flowactions_connectors.cdc \
     0xe4a8713903104ee5 \
     0 \
     null \
     --network testnet
   ```

### Benefits

✅ **Composability** - Markets can now plug into any DeFi protocol using FlowActions connectors
✅ **Flexibility** - Source/Sink pattern allows easy swapping of yield strategies
✅ **Standardization** - Uses Flow ecosystem's standard DeFi interface
✅ **Fallback Support** - Maintains backward compatibility with direct vault operations

### Usage

**Check FlowActions Status:**
```bash
flow scripts execute scripts/get_flowactions_status.cdc \
  0xe4a8713903104ee5 \
  0 \
  --network testnet
```

**Setup Connectors:**
```bash
flow transactions send transactions/setup_flowactions_connectors.cdc \
  0xe4a8713903104ee5 \
  0 \
  1000000.0 \
  --network testnet \
  --signer trixy-latest-account
```

### Future Enhancements

**Planned integrations:**
1. **Multi-Protocol Routing** - Dynamic yield optimization
2. **AutoBalancer** - Automated rebalancing across multiple yield protocols

**Current Limitations:**
- FlowActions is in **beta** - interfaces may change
- Connectors are optional - markets work without them
- Setup requires manual transaction after market creation

**Resources:**
- FlowActions: [github.com/onflow/FlowActions](https://github.com/onflow/FlowActions)
- Testnet deployments available at addresses like `0x4c2ff9dd03ab442f`

## Price Oracle Integration

### Overview

The `PriceOracle` contract provides real-time FLOW price data and dynamic APY calculations for staking protocols. It's updated automatically every 5 minutes by a cron service (`../cron-oracle`).

### Features

- **Real-time Price Updates**: FLOW/USD price updated every 5 minutes from CoinGecko
- **Dynamic APY Calculation**: APY adjusts based on FLOW price movements
- **Protocol Comparison**: Compare APYs across Ankr, Increment, and Figment
- **Yield Projections**: Calculate expected yield and payouts
- **Price History**: All price updates stored in PostgreSQL database

### Price Update Flow

```
CoinGecko API → Cron Service → PriceOracle Contract → Database
    (Real price)   (Every 5 min)   (On-chain update)   (PostgreSQL)
```

### Usage Examples

**Get current FLOW price:**
```cadence
import PriceOracle from 0xe3f7e4d39675d8d3

access(all) fun main(): UFix64 {
    return PriceOracle.getFlowPrice()
}
```

**Calculate protocol APY:**
```cadence
import PriceOracle from 0xe3f7e4d39675d8d3

access(all) fun main(protocol: String): UFix64 {
    return PriceOracle.calculateAPY(protocol: protocol)
}
```

**Get best protocol:**
```cadence
import PriceOracle from 0xe3f7e4d39675d8d3

access(all) fun main(): String {
    return PriceOracle.getBestProtocol()
}
```

### Cron Service

The automated price updater (`cron-oracle`) runs continuously:

1. Fetches FLOW/USD price from CoinGecko API
2. Updates PriceOracle contract on Flow blockchain
3. Saves price history to PostgreSQL database
4. Logs all operations

**Deployment:** See `cron-oracle/README.md` for setup instructions

### APY Calculation

The oracle dynamically adjusts APY based on FLOW price:

```cadence
baseAPY = {
    "ankr": 12.5%,
    "increment": 15.3%,
    "figment": 10.8%
}

priceImpact = 1.0 + (1.0 - flowPrice)
adjustedAPY = baseAPY * priceImpact

// Clamped between 5% and 50%
```

**Example:**
- FLOW price = $0.28
- Increment base APY = 15.3%
- Price impact = 1.0 + (1.0 - 0.28) = 1.72
- Adjusted APY = 15.3% × 1.72 = 26.3%

### Events

**PriceUpdated:**
```cadence
event PriceUpdated(
    oldPrice: UFix64,
    newPrice: UFix64,
    updater: Address,
    timestamp: UFix64
)
```

**APYCalculated:**
```cadence
event APYCalculated(
    protocol: String,
    apy: UFix64,
    price: UFix64,
    timestamp: UFix64
)
```

### Database Schema

Price history is stored in `price_oracle` table:

```sql
CREATE TABLE price_oracle (
    id UUID PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL,
    price_usd DECIMAL(20, 8) NOT NULL,
    tx_hash TEXT,
    block_number BIGINT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

## Integration with Backend

The backend indexer monitors these contracts:
- Indexes all events (MarketCreated, BetPlaced, PriceUpdated, etc.)
- Stores data in PostgreSQL for fast queries
- Provides REST API for frontend
- Syncs with PriceOracle for real-time APY data

See `backend`, `indexer`, and `cron-oracle` for implementation details.

## License

MIT
