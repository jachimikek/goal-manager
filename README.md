# Goal Manager 📈

A professional blockchain-based goal tracking system for individuals and organizations to set, track, and achieve their objectives while earning professional certifications.

## Overview

Goal Manager revolutionizes personal and professional development by bringing goal tracking to the blockchain. Set ambitious goals, achieve milestones, and earn verifiable professional certifications as NFTs that showcase your commitment to excellence.

## Features

### 🎯 Core Functionality
- **Set Goals**: Define clear goals with detailed milestone descriptions
- **Achieve Goals**: Mark goals as achieved and build your track record
- **Remove Goals**: Delete goals that are no longer relevant
- **Revise Goals**: Update goal details to reflect changing priorities

### 🏅 Professional Certifications (NFT Rewards)
Earn blockchain-verified certifications:
- **Goal Starter** - Achieve your first goal
- **Bronze Achiever** - Complete 10 goals
- **Silver Performer** - Complete 50 goals
- **Gold Excellence** - Complete 100 goals

### 📊 Performance Metrics
- Total goals set
- Goals achieved
- Pending goals
- Certification status

## Smart Contract Functions

### Public Functions

#### `set-goal`
```clarity
(set-goal (goal-title (string-utf8 256)) (milestone-description (string-utf8 1024)))
```
Create a new goal with a title and detailed milestone description.

#### `achieve-goal`
```clarity
(achieve-goal (goal-id uint))
```
Mark a goal as achieved and check for certification eligibility.

#### `remove-goal`
```clarity
(remove-goal (goal-id uint))
```
Remove an unachieved goal from your records.

#### `revise-goal`
```clarity
(revise-goal (goal-id uint) (goal-title (string-utf8 256)) (milestone-description (string-utf8 1024)))
```
Update the details of an existing goal.

### Read-Only Functions

#### `retrieve-goal`
```clarity
(retrieve-goal (goal-id uint) (user principal))
```
View details of a specific goal.

#### `fetch-user-metrics`
```clarity
(fetch-user-metrics (user principal))
```
Check a user's overall performance metrics.

#### `check-certification`
```clarity
(check-certification (user principal) (certification-type (string-ascii 50)))
```
Verify if a user has earned a specific certification.

## Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for blockchain interaction

### Installation
```bash
git clone https://github.com/jachimikek/goal-manager
cd goal-manager
clarinet integrate
```

### Testing
```bash
clarinet test
```

### Deployment
```bash
clarinet deployments generate --mainnet
clarinet deployments apply -p deployments/mainnet.plan.yaml
```

## Usage Example

```clarity
;; Set a new professional goal
(contract-call? .goal-manager set-goal 
    u"Launch new product line" 
    u"Successfully launch and achieve $1M in revenue within first quarter")

;; Achieve the goal
(contract-call? .goal-manager achieve-goal u0)

;; Check your metrics
(contract-call? .goal-manager fetch-user-metrics tx-sender)
```

## Architecture

### Data Structure
- **Goals Map**: Stores goal information with user-specific access
- **User Metrics Map**: Tracks performance statistics
- **Certification Registry**: Records professional certifications earned

### Security & Validation
- User-specific goal management
- Prevention of duplicate achievements
- Comprehensive input validation
- Immutable achievement records

## Professional Framework

### Goal Lifecycle
1. **Set** - Define clear, measurable goals
2. **Active** - Work towards achievement
3. **Achieved** - Complete and earn recognition
4. **Remove** - Clean up outdated goals

### Certification System
Professional certifications are automatically issued as NFTs when you reach significant milestones. These blockchain-verified credentials can be shared with employers, clients, or professional networks.

## Business Applications

- **Performance Management**: Track employee goals and achievements
- **Professional Development**: Document career progression
- **Client Deliverables**: Transparent milestone tracking
- **Team Objectives**: Coordinate organizational goals

## Contributing

We welcome contributions from the community. Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting PRs.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
