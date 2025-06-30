# Knowledge Graph Network Smart Contract

A Clarity smart contract for building a decentralized knowledge graph that enables researchers to register documents, track citations, and earn rewards for knowledge contributions.

## Overview

This smart contract creates a blockchain-based knowledge management system where researchers can:

- **Register Research Documents**: Submit papers with metadata including title, category, and abstract
- **Track Citations**: Record connections between documents with context and relevance scores
- **Verify Authenticity**: Allow authorized verifiers to validate document authenticity
- **Earn Rewards**: Accumulate contribution points based on citations and document verification
- **Build Knowledge Networks**: Create interconnected webs of research through citation tracking

## Features

### Core Functionality

- **Document Registration**: Researchers can register documents with comprehensive metadata
- **Citation Management**: Track citations between documents with relevance scoring (1-10)
- **Verification System**: Authorized verifiers can validate document authenticity
- **Reward System**: Contributors earn points based on citation relevance and document verification
- **Analytics**: Track researcher profiles, category metrics, and citation counts

### Data Structures

- **Documents**: Store research papers with title, researcher, timestamp, category, abstract, and verification status
- **Citations**: Record relationships between documents with context and relevance scores
- **Researcher Profiles**: Track total documents, citations received, and knowledge scores
- **Category Metrics**: Aggregate statistics for different research categories
- **Contribution Points**: Reward system for valuable knowledge contributions

## Usage

### Register a Document

```clarity
(contract-call? .knowledge-graph register-document
  "doc-001"
  "Machine Learning in Healthcare"
  "AI/ML"
  "This paper explores the applications of machine learning techniques in medical diagnosis...")
```

### Add a Citation

```clarity
(contract-call? .knowledge-graph add-citation
  "doc-002"  ;; citing document
  "doc-001"  ;; cited document
  (some "Referenced for ML methodology")
  u8)        ;; relevance score (1-10)
```

### Verify a Document

```clarity
(contract-call? .knowledge-graph verify-document "doc-001")
```

### Query Functions

```clarity
;; Get document details
(contract-call? .knowledge-graph get-document-details "doc-001")

;; Get researcher profile
(contract-call? .knowledge-graph get-researcher-profile 'SP1HTBVD3S...)

;; Get citation count
(contract-call? .knowledge-graph get-citation-count "doc-001")

;; Get category metrics
(contract-call? .knowledge-graph get-category-metrics "AI/ML")
```

## Contract Functions

### Public Functions

| Function | Description | Access |
|----------|-------------|---------|
| `register-document` | Register a new research document | Any user |
| `add-citation` | Record citation between documents | Document owner |
| `verify-document` | Mark document as verified | Authorized verifiers |
| `add-verifier` | Add new document verifier | Contract owner |
| `remove-verifier` | Remove document verifier | Contract owner |
| `claim-contributions` | Claim reward points | Any user |

### Read-Only Functions

| Function | Description |
|----------|-------------|
| `get-document-details` | Retrieve document information |
| `get-citation-details` | Get citation relationship data |
| `get-citation-count` | Get total citations for document |
| `get-researcher-profile` | Get researcher statistics |
| `get-category-metrics` | Get category-wide metrics |
| `get-contribution-points` | Get user's reward points |
| `is-verifier` | Check if user is authorized verifier |

## Validation & Security

The contract includes comprehensive validation:

- **Input Validation**: All string inputs are validated for length and content
- **Authorization Checks**: Ensures only authorized users can perform restricted actions
- **Duplicate Prevention**: Prevents duplicate document registration and citations
- **Self-Citation Prevention**: Documents cannot cite themselves
- **Principal Validation**: Validates wallet addresses to prevent null/invalid addresses

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| `u100` | `ERR_UNAUTHORIZED` | User lacks permission for action |
| `u101` | `ERR_DUPLICATE_ENTRY` | Attempting to create duplicate entry |
| `u102` | `ERR_NOT_FOUND` | Requested resource doesn't exist |
| `u103` | `ERR_SELF_CITATION` | Document cannot cite itself |
| `u104` | `ERR_INVALID_PARAMS` | Invalid parameter values |
| `u105` | `ERR_BAD_INPUT` | Malformed input data |

## Reward System

The contract implements a point-based reward system:

- **Citation Rewards**: Earn points equal to citation relevance score (1-10)
- **Verification Bonus**: +50 points when document is verified
- **Knowledge Score**: Cumulative score based on all contributions
- **Contribution Claims**: Users can claim accumulated points (implementation-specific rewards)

## Deployment

Deploy using Clarinet or Stacks CLI:

```bash
clarinet deploy --network testnet
```

## Development

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet)
- Stacks wallet for testing

### Testing

```bash
clarinet test
```

### Local Development

```bash
clarinet console
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request


## Future Enhancements

- **Token Integration**: Implement actual token rewards for contributions
- **Advanced Search**: Add full-text search capabilities
- **Peer Review**: Implement decentralized peer review system
- **Version Control**: Track document revisions and updates
- **Reputation System**: Advanced reputation metrics beyond simple citation counts