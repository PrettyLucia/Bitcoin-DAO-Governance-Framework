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

;; Emergency and Governance Controls
(define-data-var emergency-stop-activated bool false)
(define-data-var governance-pause-threshold uint u3)
(define-data-var total-governance-tokens uint u0)
(define-data-var next-proposal-id uint u0)
(define-data-var next-upgrade-id uint u0)

;; Treasury Management System
(define-public (create-treasury-account
  (initial-balance uint)
  (allowed-categories (list 5 (string-ascii 50)))
)
  (begin
    (asserts! (not (var-get emergency-stop-activated)) ERR_EMERGENCY_STOP)
    
    (map-set treasury-accounts 
      { account: tx-sender }
      {
        balance: initial-balance,
        allowed-categories: allowed-categories,
        last-withdrawal-block: stacks-block-height
      }
    )
    
    (ok true)
  ))

;; Governance Parameters Management
(define-private (get-governance-parameters)
  {
    min-proposal-voting-power: (default-to u100 
      (get value (map-get? governance-parameters { param-name: "min-proposal-voting-power" }))),
    proposal-creation-delay: (default-to u144 
      (get value (map-get? governance-parameters { param-name: "proposal-creation-delay" }))),
    proposal-voting-duration: (default-to u1440 
      (get value (map-get? governance-parameters { param-name: "proposal-voting-duration" }))),
    proposal-execution-delay: (default-to u288 
      (get value (map-get? governance-parameters { param-name: "proposal-execution-delay" }))),
    treasury-withdrawal-cooldown: (default-to u576 
      (get value (map-get? governance-parameters { param-name: "treasury-withdrawal-cooldown" })))
  }
)

;; Voter History Management
(define-private (update-voter-proposal-history
  (voter principal)
  (proposal-id uint)
)
  (let (
    (current-profile (unwrap-panic (map-get? voter-profiles { voter: voter })))
  )
  (map-set voter-profiles
    { voter: voter }
    (merge current-profile {
      reputation-score: (+ (get reputation-score current-profile) u10)
    })
  )
))

(define-private (update-voter-vote-history
  (voter principal)
  (proposal-id uint)
  (vote-direction bool)
  (voting-power uint)
)
  (let (
    (current-profile (unwrap-panic (map-get? voter-profiles { voter: voter })))
    (new-vote-history { 
      proposal-id: proposal-id, 
      vote-direction: vote-direction, 
      voting-power: voting-power 
    })
  )
  (map-set voter-profiles
    { voter: voter }
    (merge current-profile {
      vote-history: (unwrap-panic 
        (as-max-len? 
          (append (get vote-history current-profile) new-vote-history) 
          u20
        )
      ),
      reputation-score: (if vote-direction 
        (+ (get reputation-score current-profile) u5)
        (- (get reputation-score current-profile) u2)
      )
    })
  )
))

;; Initial Setup and Configuration
(define-public (register-voter
  (initial-voting-power uint)
  (specialized-categories (optional (list 5 { 
    category: (string-ascii 50), 
    weight-multiplier: uint 
  })))
)
  (begin
    (asserts! (> initial-voting-power u0) ERR_INSUFFICIENT_VOTING_POWER)
    
    (map-set voter-profiles
      { voter: tx-sender }
      {
        base-voting-power: initial-voting-power,
        delegated-voting-power: u0,
        delegated-to: none,
        total-delegated-from: (list),
        last-voting-block: stacks-block-height,
        reputation-score: u0,
        slashing-points: u0,
        vote-history: (list),
        specialized-voting-weights: (default-to (list) specialized-categories)
      }
    )
    
    ;; Increment total governance tokens
    (var-set total-governance-tokens 
      (+ (var-get total-governance-tokens) initial-voting-power)
    )
    
    (ok true)
  )
)

;; Initialize Governance Parameters
(map-set governance-parameters 
  { param-name: "min-proposal-voting-power" }
  { 
    value: u100, 
    last-updated-block: u0, 
    update-cooldown: u1440 
  }
)

(map-set governance-parameters 
  { param-name: "proposal-creation-delay" }
  { 
    value: u144, 
    last-updated-block: u0, 
    update-cooldown: u1440 
  }
)

;; Initial Configuration for Contract Owner
(map-set voter-profiles 
  { voter: CONTRACT_OWNER }
  {
    base-voting-power: u10000,
    delegated-voting-power: u0,
    delegated-to: none,
    total-delegated-from: (list),
    last-voting-block: u0,
    reputation-score: u100,
    slashing-points: u0,
    vote-history: (list),
    specialized-voting-weights: (list)
  }
)

(define-constant ERR_ALREADY_VOTED (err u12))
(define-constant ERR_ZERO_VOTE_POWER (err u13))
(define-constant ERR_PROPOSAL_THRESHOLD_NOT_MET (err u14))
(define-constant ERR_PROTOCOL_COOLDOWN (err u15))
(define-constant ERR_INVALID_VETO (err u16))
(define-constant ERR_CANCELLATION_WINDOW_CLOSED (err u17))
(define-constant ERR_INVALID_TRANSACTION (err u18))
(define-constant ERR_NOT_ACTIVE_MEMBER (err u19))
(define-constant ERR_STAKING_PERIOD_ACTIVE (err u20))

(define-constant PROPOSAL_TYPE_MULTISIG u4)
(define-constant PROPOSAL_TYPE_COMMUNITY_FUND u5)
(define-constant PROPOSAL_TYPE_PROTOCOL_UPGRADE u6)

;; Staking and Rewards System
(define-map staking-positions
  {
    staker: principal
  }
  {
    amount: uint,
    locked-until-block: uint,
    reward-multiplier: uint,
    auto-compound: bool,
    unclaimed-rewards: uint,
    last-claim-block: uint
  }
)

(define-data-var staking-rewards-rate uint u5) ;; 5 basis points per block
(define-data-var staking-rewards-pool uint u0)

;; Community Treasury and Grants
(define-map community-fund-proposals
  {
    fund-id: uint
  }
  {
    applicant: principal,
    requested-amount: uint,
    category: (string-ascii 50),
    milestones: (list 5 {
      description: (string-ascii 100),
      amount: uint,
      completed: bool
    }),
    approved: bool,
    votes-needed: uint,
    votes-received: uint,
    proposal-id: uint
  }
)

(define-data-var next-fund-id uint u0)
(define-data-var community-treasury-balance uint u0)

;; Multi-signature Transaction System
(define-map multisig-transactions
  {
    transaction-id: uint
  }
  {
    creator: principal,
    contract-to-call: principal,
    function-to-call: (string-ascii 128),
    function-args: (list 10 (buff 256)),
    required-signatures: uint,
    signers: (list 10 principal),
    executed: bool,
    created-at-block: uint,
    expiration-block: uint
  }
)

(define-data-var next-transaction-id uint u0)

;; Reputation and Governance Tiers
(define-map governance-tiers
  {
    tier-level: uint
  }
  {
    name: (string-ascii 50),
    min-reputation: uint,
    voting-power-multiplier: uint,
    proposal-discount: uint,
    special-rights: (list 5 (string-ascii 50))
  }
)

;; Protocol Cooldown System
(define-map protocol-actions
  {
    action-type: (string-ascii 50)
  }
  {
    last-executed: uint,
    cooldown-period: uint,
    calls-in-period: uint,
    max-calls-in-period: uint
  }
)

;; Quadratic Voting Implementation
(define-private (calculate-quadratic-vote-power (base-power uint))
  (let (
    (sqrt-power (sqrti base-power))
  )
    sqrt-power
  )
)

(define-public (unstake-tokens (amount uint))
  (let (
    (staking-position (unwrap! (map-get? staking-positions { staker: tx-sender }) 
                               ERR_NOT_ACTIVE_MEMBER))
  )
    (asserts! (not (var-get emergency-stop-activated)) ERR_EMERGENCY_STOP)
    (asserts! (<= amount (get amount staking-position)) ERR_INSUFFICIENT_VOTING_POWER)
    (asserts! (<= stacks-block-height (get locked-until-block staking-position)) 
              ERR_STAKING_PERIOD_ACTIVE)
    
    (map-set staking-positions
      { staker: tx-sender }
      (merge staking-position {
        amount: (- (get amount staking-position) amount)
      })
    )
    
    ;; Update voter profile
    (let (
      (voter-profile (unwrap-panic (map-get? voter-profiles { voter: tx-sender })))
    )
      (map-set voter-profiles
        { voter: tx-sender }
        (merge voter-profile {
          base-voting-power: (- (get base-voting-power voter-profile) amount)
        })
      )
    )
    
    (ok true)
  )
)

;; Community Fund Functions
(define-public (submit-fund-request
  (requested-amount uint)
  (category (string-ascii 50))
  (milestones (list 5 {
    description: (string-ascii 100),
    amount: uint,
    completed: bool
  }))
)
  (let (
    (fund-id (var-get next-fund-id))
    (params (get-governance-parameters))
    (voter-profile (unwrap! (map-get? voter-profiles { voter: tx-sender }) ERR_NOT_ACTIVE_MEMBER))
    (tier-voting-threshold (default-to u10 
      (get value (map-get? governance-parameters { param-name: "fund-request-votes-needed" }))))
  )
    (asserts! (not (var-get emergency-stop-activated)) ERR_EMERGENCY_STOP)
    (asserts! (>= (get reputation-score voter-profile) u50) ERR_INSUFFICIENT_VOTING_POWER)
    (asserts! (> requested-amount u0) ERR_ZERO_VOTE_POWER)
    
    ;; Create fund request
    (map-set community-fund-proposals
      { fund-id: fund-id }
      {
        applicant: tx-sender,
        requested-amount: requested-amount,
        category: category,
        milestones: milestones,
        approved: false,
        votes-needed: tier-voting-threshold,
        votes-received: u0,
        proposal-id: u0
      }
    )
    
    ;; Increment fund ID counter
    (var-set next-fund-id (+ fund-id u1))
    
    (ok fund-id)
  )
)


(define-public (vote-on-fund-request (fund-id uint) (support bool))
  (let (
    (fund-proposal (unwrap! (map-get? community-fund-proposals { fund-id: fund-id })
                           ERR_INVALID_PROPOSAL))
    (voter-profile (unwrap! (map-get? voter-profiles { voter: tx-sender }) 
                           ERR_NOT_ACTIVE_MEMBER))
    (voting-power (+ (get base-voting-power voter-profile) 
                     (get delegated-voting-power voter-profile)))
  )
    (asserts! (not (var-get emergency-stop-activated)) ERR_EMERGENCY_STOP)
    (asserts! (> voting-power u0) ERR_INSUFFICIENT_VOTING_POWER)
    (asserts! (not (get approved fund-proposal)) ERR_VOTING_CLOSED)
    
    ;; If supporting, add to votes received
    (if support
      (map-set community-fund-proposals
        { fund-id: fund-id }
        (merge fund-proposal {
          votes-received: (+ (get votes-received fund-proposal) u1)
        })
      )
      true
    )
    
    ;; Check if fund request is now approved
    (let (
      (updated-fund (unwrap-panic (map-get? community-fund-proposals { fund-id: fund-id })))
    )
      (if (and (not (get approved updated-fund))
               (>= (get votes-received updated-fund) (get votes-needed updated-fund)))
        (map-set community-fund-proposals
          { fund-id: fund-id }
          (merge updated-fund {
            approved: true
          })
        )
        true
      )
    )
    
    (ok support)
  )
)