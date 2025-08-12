# BlockDividend Protocol

A sophisticated yield distribution protocol built on Stacks blockchain, featuring stratified reward mechanisms, decentralized governance, and advanced capital optimization strategies.

## Overview

BlockDividend revolutionizes traditional staking by implementing a three-tier capital stratification system that rewards larger participants with enhanced yield multipliers while maintaining fairness through democratic governance mechanisms.

## Core Features

### Stratified Capital Deployment
- **Bronze Tier**: 100+ STX (1.0x multiplier)
- **Silver Tier**: 1,000+ STX (1.25x multiplier) 
- **Gold Tier**: 10,000+ STX (1.5x multiplier)

### Decentralized Governance
- Referendum-based decision making
- Weighted voting based on capital and tier
- Temporal controls for proposal lifecycle

### Advanced Dividend Distribution
- Epoch-based yield calculations
- Proportional rewards with tier bonuses
- Automated dividend claiming

### Security & Controls
- Temporal withdrawal locks
- Emergency recovery protocols
- Guardian-level access controls

### Network Incentives
- Referral reward system
- Community growth mechanisms
- Sponsor-beneficiary relationships

## Architecture

```
BlockDividend Protocol
├── Capital Deployment Layer
├── Dividend Distribution Engine
├── Governance Framework
├── Security Controls
└── Network Incentives
```

## Getting Started

### Prerequisites
- Stacks wallet with STX tokens
- Minimum 100 STX for Bronze tier participation

### Deployment
1. Deploy the contract to Stacks blockchain
2. Initialize with protocol guardian address
3. Begin accepting capital deployments

### Participation

#### Deploy Capital
```clarity
(contract-call? .blockdividend deploy-capital u100000000) ;; 100 STX
```

#### Claim Dividends
```clarity
(contract-call? .blockdividend claim-dividends)
```

#### Participate in Governance
```clarity
(contract-call? .blockdividend initiate-referendum "Proposal description")
(contract-call? .blockdividend cast-ballot u1 true)
```

## API Reference

### Core Functions

#### `deploy-capital (allocation uint)`
Deploy STX tokens to earn stratified dividends

#### `withdraw-capital (withdrawal-amount uint)`
Withdraw capital with temporal lock enforcement

#### `claim-dividends ()`
Claim accumulated dividend rewards

#### `initiate-referendum (proposition string-utf8)`
Create governance proposal (Silver tier required)

#### `cast-ballot (referendum-id uint) (ballot-choice bool)`
Vote on active referendums

### Read-Only Functions

#### `get-participant-holdings (participant principal)`
Query participant's total capital deployment

#### `compute-dividends (participant principal)`
Calculate pending dividend rewards

#### `get-capital-stratum (participant principal)`
Get participant's current tier level

## Governance

The protocol employs a democratic governance system where participants can:
- Propose protocol modifications
- Vote on operational changes  
- Influence reward distribution policies

Voting weight is calculated as: `holdings × stratum ÷ 100`

## Security Model

### Temporal Controls
- **Withdrawal Lock**: 100 blocks between withdrawals
- **Referendum Duration**: 1,440 blocks (~10 days)
- **Emergency Timelock**: 144 blocks (~24 hours)

### Access Controls
- Protocol guardian for critical operations
- Participant-level permissions
- Emergency recovery mechanisms

## Economic Model

### Revenue Sources
- External yield generation
- Network transaction fees
- Partnership integrations

### Distribution Mechanism
- Proportional to capital deployment
- Enhanced by tier multipliers
- Democratic governance influence

## Development

### Testing
```bash
clarinet test
```

### Deployment
```bash
clarinet deploy --testnet
```

### Contract Verification
Verify contract deployment and initialize guardian permissions.
