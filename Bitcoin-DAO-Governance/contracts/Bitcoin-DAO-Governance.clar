;; Expanded Core Constants and Error Definitions
(define-constant CONTRACT_OWNER tx-sender)
(define-constant CONTRACT_VERSION u3)

;; Comprehensive Error Codes
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_INVALID_PROPOSAL (err u2))
(define-constant ERR_VOTING_CLOSED (err u3))
(define-constant ERR_INSUFFICIENT_VOTING_POWER (err u4))
(define-constant ERR_DELEGATION_LIMIT_REACHED (err u5))
(define-constant ERR_PROPOSAL_EXECUTION_FAILED (err u6))
(define-constant ERR_EMERGENCY_STOP (err u7))
(define-constant ERR_INVALID_DELEGATION (err u8))
(define-constant ERR_TREASURY_INSUFFICIENT_FUNDS (err u9))
(define-constant ERR_INVALID_UPGRADE (err u10))
(define-constant ERR_TIMELOCK_ACTIVE (err u11))

;; Enhanced Proposal Types Enum
(define-constant PROPOSAL_TYPE_STANDARD u0)
(define-constant PROPOSAL_TYPE_TREASURY u1)
(define-constant PROPOSAL_TYPE_PARAMETER_UPDATE u2)
(define-constant PROPOSAL_TYPE_CONTRACT_UPGRADE u3)

;; Proposal Structure
(define-map proposals
  {
    proposal-id: uint
  }
  {
    proposer: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    proposal-type: uint,
    creation-block: uint,
    voting-start-block: uint,
    voting-end-block: uint,
    execution-block: uint,
    total-votes-for: uint,
    total-votes-against: uint,
    executed: bool,
    proposal-data: (optional (buff 256)),
    execution-result: (optional (buff 256)),
    veto-power-activated: bool,
    timelock-expiration: uint
  }
)

;; Enhanced Voter Profile with Advanced Features
(define-map voter-profiles
  {
    voter: principal
  }
  {
    base-voting-power: uint,
    delegated-voting-power: uint,
    delegated-to: (optional principal),
    total-delegated-from: (list 10 principal),
    last-voting-block: uint,
    reputation-score: uint,
    slashing-points: uint,
    vote-history: (list 20 { 
      proposal-id: uint, 
      vote-direction: bool, 
      voting-power: uint 
    }),
    specialized-voting-weights: (list 5 { 
      category: (string-ascii 50), 
      weight-multiplier: uint 
    })
  }
)

;; Treasury Management
(define-map treasury-accounts
  {
    account: principal
  }
  {
    balance: uint,
    allowed-categories: (list 5 (string-ascii 50)),
    last-withdrawal-block: uint
  }
)

;; Advanced Voting and Delegation Mechanisms
(define-map proposal-votes
  {
    proposal-id: uint,
    voter: principal
  }
  {
    vote-power: uint,
    vote-direction: bool,
    voted-at-block: uint,
    quadratic-weight: uint,
    specialized-category-votes: (list 5 { 
      category: (string-ascii 50), 
      vote-weight: uint 
    })
  }
)

;; Governance Parameters Management
(define-map governance-parameters
  {
    param-name: (string-ascii 50)
  }
  {
    value: uint,
    last-updated-block: uint,
    update-cooldown: uint
  }
)

;; Contract Upgrade Mechanism
(define-map contract-upgrades
  {
    upgrade-id: uint
  }
  {
    new-contract-address: principal,
    proposed-by: principal,
    upgrade-block: uint,
    approved: bool,
    implementation-details: (optional (string-ascii 500))
  }
)


