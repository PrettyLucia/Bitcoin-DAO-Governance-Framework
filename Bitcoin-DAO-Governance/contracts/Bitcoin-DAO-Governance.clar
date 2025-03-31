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
