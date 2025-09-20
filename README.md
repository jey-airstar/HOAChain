# HOAChain

A transparent, decentralized voting system for residential association bylaws and community decisions built on the Stacks blockchain using Clarity smart contracts.

## Overview

HOAChain enables Homeowners Association (HOA) members to propose, vote on, and track community decisions with complete transparency and immutability. The system ensures democratic governance while maintaining security and preventing voting fraud through blockchain technology.

## Features

- **Decentralized Governance**: All voting and decisions are recorded on the Stacks blockchain
- **Member Management**: Secure addition and removal of HOA members with proper authorization
- **Proposal System**: Create categorized proposals with customizable voting duration
- **Transparent Voting**: All votes are publicly verifiable while maintaining member privacy
- **Weighted Voting**: Support for different voting power based on membership type
- **Automatic Finalization**: Proposals are automatically finalized based on quorum and majority rules
- **Multiple Categories**: Support for bylaws, budget, maintenance, policy, and other proposal types
- **Quorum Requirements**: Ensures adequate participation with 50% quorum requirement

## Technical Specifications

- **Blockchain**: Stacks
- **Smart Contract Language**: Clarity 2.0
- **Epoch**: 2.5
- **Testing Framework**: Vitest with Clarinet SDK
- **Development Tools**: Clarinet, TypeScript

## Project Structure

```
HOAChain/
├── README.md
└── HOAChain_contract/
    ├── contracts/
    │   └── HOAChain.clar          # Main smart contract
    ├── tests/
    │   └── HOAChain.test.ts       # Test suite
    ├── settings/
    │   ├── Devnet.toml
    │   ├── Testnet.toml
    │   └── Mainnet.toml
    ├── Clarinet.toml              # Project configuration
    ├── package.json               # Dependencies and scripts
    └── tsconfig.json              # TypeScript configuration
```

## Installation

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet) - Stacks development environment
- [Node.js](https://nodejs.org/) (version 16 or higher)
- [Git](https://git-scm.com/)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd HOAChain
```

2. Navigate to the contract directory:
```bash
cd HOAChain_contract
```

3. Install dependencies:
```bash
npm install
```

4. Run tests:
```bash
npm test
```

## Usage Examples

### Initialize the Contract

After deployment, initialize the contract to set up the first HOA member:

```clarity
(contract-call? .HOAChain initialize)
```

### Add HOA Members

Existing members can add new members to the HOA:

```clarity
(contract-call? .HOAChain add-member 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### Create a Proposal

Members can create proposals for community decisions:

```clarity
(contract-call? .HOAChain create-proposal
    u"Install New Playground Equipment"
    u"Proposal to install new playground equipment in the community park area. Estimated cost: $15,000"
    u1440  ;; Voting duration in blocks (approximately 10 days)
    "budget")
```

### Vote on Proposals

Members can vote on active proposals:

```clarity
;; Vote in favor
(contract-call? .HOAChain vote u1 true)

;; Vote against
(contract-call? .HOAChain vote u1 false)
```

### Finalize Proposals

After the voting period ends, anyone can finalize the proposal:

```clarity
(contract-call? .HOAChain finalize-proposal u1)
```

## Contract Functions Documentation

### Public Functions

#### `initialize()`
Initializes the contract and sets the deployer as the first HOA member.

#### `add-member(new-member: principal)`
Adds a new member to the HOA. Only existing members can add new members.

#### `remove-member(member: principal)`
Removes a member from the HOA. Only the contract owner can remove members.

#### `create-proposal(title, description, voting-duration, category)`
Creates a new proposal for community voting.
- `title`: Proposal title (max 100 characters)
- `description`: Detailed description (max 500 characters)
- `voting-duration`: Duration in blocks
- `category`: Proposal category ("bylaw", "budget", "maintenance", "policy", "other")

#### `vote(proposal-id: uint, vote-for: bool)`
Casts a vote on an active proposal.
- `proposal-id`: ID of the proposal to vote on
- `vote-for`: true for "yes" vote, false for "no" vote

#### `finalize-proposal(proposal-id: uint)`
Finalizes a proposal after the voting period ends and determines the outcome.

#### `update-voting-power(member: principal, new-power: uint)`
Updates the voting power of a member. Only the contract owner can perform this action.

### Read-Only Functions

#### `is-hoa-member(member: principal)`
Checks if an address is a registered HOA member.

#### `get-proposal(proposal-id: uint)`
Returns detailed information about a specific proposal.

#### `get-proposal-count()`
Returns the total number of proposals created.

#### `get-member-count()`
Returns the total number of HOA members.

#### `has-voted(proposal-id: uint, voter: principal)`
Checks if a member has already voted on a specific proposal.

#### `get-voting-power(member: principal)`
Returns the voting power of a specific member.

#### `get-vote(proposal-id: uint, voter: principal)`
Returns the vote cast by a specific member on a proposal.

#### `is-proposal-active(proposal-id: uint)`
Checks if a proposal is currently active and accepting votes.

#### `get-contract-owner()`
Returns the contract owner address.

## Deployment Guide

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy the contract:
```clarity
::deploy_contracts
```

3. Initialize the contract:
```clarity
(contract-call? .HOAChain initialize)
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`

2. Deploy to testnet:
```bash
clarinet deploy --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`

2. Deploy to mainnet:
```bash
clarinet deploy --mainnet
```

## Security Notes

### Access Control
- Contract deployment creates the first HOA member (contract owner)
- Only existing members can add new members
- Only the contract owner can remove members
- Only the contract owner can update voting power

### Voting Security
- One vote per member per proposal
- Votes are immutable once cast
- Voting only allowed during active proposal periods
- Quorum requirement ensures adequate participation

### Best Practices
- Regular audits of member list
- Careful consideration of voting duration
- Clear proposal descriptions
- Transparent communication of voting results

### Known Limitations
- Fixed 50% quorum requirement
- Simple majority voting (no supermajority options)
- No vote delegation mechanism
- No proposal amendment process

## Error Codes

- `u100`: Unauthorized access
- `u101`: Proposal not found
- `u102`: Already voted on this proposal
- `u103`: Voting period has ended
- `u104`: Voting has not started yet
- `u105`: Invalid member
- `u106`: Proposal is no longer active
- `u107`: Insufficient votes for quorum

## Development

### Running Tests

```bash
npm test
```

### Test Coverage

```bash
npm run test:report
```

### Watch Mode

```bash
npm run test:watch
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the ISC License.

## Version

Current version: 1.0.0

## Support

For questions, issues, or contributions, please use the project's issue tracker or contact the development team.