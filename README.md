# LaunchpadOperator

LaunchpadOperator is an address reputation system smart contract for token launchpad operator success rate scoring on the Stacks blockchain. This contract provides a decentralized mechanism to track and evaluate the performance of launchpad operators based on their project success rates.

## Features

- **Operator Registration**: Anyone can register as a launchpad operator with an initial neutral reputation score
- **Project Tracking**: Comprehensive tracking of projects including launch details, status, and completion
- **Reputation Scoring**: Automated calculation of reputation scores based on project success rates (0-100 scale)
- **Authorized Evaluation**: Controlled project outcome evaluation through authorized evaluators
- **Transparent Metrics**: Public access to operator statistics and project histories
- **Success Rate Calculation**: Real-time calculation of operator success percentages

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity v2
- **Epoch**: 2.5
- **Contract Version**: 1.0.0

### Key Data Structures

- **Operator Reputation**: Tracks total projects, successful projects, failed projects, reputation score, and last update
- **Project Records**: Stores project details including operator, name, status, launch block, and completion block
- **Authorized Evaluators**: Manages permissions for project outcome evaluation

### Constants

- Reputation Score Range: 0-100
- Project Status Types: Pending (0), Successful (1), Failed (2)
- Initial Reputation Score: 50 (neutral)

## Installation

### Prerequisites

- [Clarinet CLI](https://docs.hiro.so/clarinet/getting-started) installed
- Node.js and npm (for development tools)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd LaunchpadOperator
```

2. Navigate to the contract directory:
```bash
cd LaunchpadOperator_contract
```

3. Install dependencies:
```bash
npm install
```

4. Check contract syntax:
```bash
clarinet check
```

## Usage Examples

### Deploying the Contract

```bash
clarinet deploy --devnet
```

### Testing the Contract

```bash
clarinet test
```

### Interacting with the Contract

#### Register as an Operator
```clarity
(contract-call? .LaunchpadOperator register-operator)
```

#### Add a New Project
```clarity
(contract-call? .LaunchpadOperator add-project 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM "My Token Project")
```

#### Update Project Outcome (Authorized Evaluators Only)
```clarity
(contract-call? .LaunchpadOperator update-project-outcome u1 true)
```

#### Query Operator Reputation
```clarity
(contract-call? .LaunchpadOperator get-operator-reputation 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## Contract Functions Documentation

### Public Functions

#### `register-operator()`
- **Description**: Registers the caller as a new launchpad operator
- **Parameters**: None
- **Returns**: `(response bool uint)` - Success confirmation
- **Initial State**: Sets reputation score to 50 with zero projects

#### `add-project(operator principal, project-name string-ascii)`
- **Description**: Adds a new project for a specified operator
- **Parameters**:
  - `operator`: Principal address of the operator
  - `project-name`: Name of the project (max 64 characters)
- **Returns**: `(response uint uint)` - Project ID on success
- **Requirements**: Operator must be registered

#### `update-project-outcome(project-id uint, successful bool)`
- **Description**: Updates the outcome of a project (success/failure)
- **Parameters**:
  - `project-id`: Unique identifier of the project
  - `successful`: Boolean indicating project success
- **Returns**: `(response bool uint)` - Success confirmation
- **Authorization**: Only contract owner or authorized evaluators

#### `authorize-evaluator(evaluator principal)`
- **Description**: Grants evaluation permissions to an address
- **Parameters**: `evaluator` - Principal to authorize
- **Returns**: `(response bool uint)` - Success confirmation
- **Authorization**: Contract owner only

#### `revoke-evaluator(evaluator principal)`
- **Description**: Revokes evaluation permissions from an address
- **Parameters**: `evaluator` - Principal to revoke
- **Returns**: `(response bool uint)` - Success confirmation
- **Authorization**: Contract owner only

### Read-Only Functions

#### `get-operator-reputation(operator principal)`
- **Description**: Retrieves complete reputation data for an operator
- **Returns**: Optional tuple with total projects, successful projects, failed projects, reputation score, and last updated block

#### `get-project(project-id uint)`
- **Description**: Retrieves project details by ID
- **Returns**: Optional tuple with operator, project name, status, launch block, and completion block

#### `get-success-rate(operator principal)`
- **Description**: Calculates operator's success rate as a percentage
- **Returns**: Uint representing success percentage (0-100)

#### `is-authorized-evaluator(evaluator principal)`
- **Description**: Checks if an address is authorized to evaluate projects
- **Returns**: Boolean indicating authorization status

#### `get-contract-owner()`
- **Description**: Returns the contract owner's address
- **Returns**: Principal of the contract owner

#### `get-next-project-id()`
- **Description**: Returns the next available project ID
- **Returns**: Uint of the next project ID

### Private Functions

#### `calculate-reputation-score(successful-projects uint, total-projects uint)`
- **Description**: Calculates reputation score based on success rate
- **Logic**: (successful_projects / total_projects) * 100, bounded between 0-100
- **Default**: Returns 50 for operators with no projects

## Deployment Guide

### Local Development (Devnet)

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy the contract:
```clarity
::deploy_contracts
```

3. Test basic functionality:
```clarity
::get_assets_maps
(contract-call? .LaunchpadOperator register-operator)
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`

2. Deploy to testnet:
```bash
clarinet deployments generate --devnet
clarinet deployments apply -p testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`

2. Deploy to mainnet:
```bash
clarinet deployments generate --mainnet
clarinet deployments apply -p mainnet
```

## Security Notes

### Access Control
- Contract deployment establishes the deployer as the contract owner
- Only the contract owner can authorize/revoke evaluators
- Project outcomes can only be updated by the contract owner or authorized evaluators
- Operator registration is permissionless

### Data Integrity
- Reputation scores are automatically calculated and cannot be manually manipulated
- Project records are immutable once created
- All state changes are recorded with block height timestamps
- Reputation scores are bounded between 0-100 to prevent overflow/underflow

### Best Practices
- Regularly audit authorized evaluators
- Implement multi-signature schemes for critical operations in production
- Monitor project evaluation patterns for potential manipulation
- Consider implementing time-based constraints for project lifecycle management

### Known Limitations
- Success rate calculation uses integer division which may lose precision
- No built-in dispute resolution mechanism for project evaluations
- Project names are limited to 64 ASCII characters
- No mechanism to remove or archive old projects

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is open source. Please refer to the license file for details.