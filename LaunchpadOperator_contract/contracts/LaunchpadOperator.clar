
;; title: LaunchpadOperator
;; version: 1.0.0
;; summary: Address reputation system for token launchpad operator success rate scoring
;; description: This contract tracks and manages reputation scores for launchpad operators based on their project success rates

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_OPERATOR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_SCORE (err u400))
(define-constant ERR_PROJECT_NOT_FOUND (err u410))

;; Minimum and maximum reputation scores
(define-constant MIN_REPUTATION_SCORE u0)
(define-constant MAX_REPUTATION_SCORE u100)

;; Project status constants
(define-constant PROJECT_STATUS_PENDING u0)
(define-constant PROJECT_STATUS_SUCCESSFUL u1)
(define-constant PROJECT_STATUS_FAILED u2)

;; data vars
(define-data-var contract-owner principal CONTRACT_OWNER)

;; data maps

;; Operator reputation data
(define-map operator-reputation
  { operator: principal }
  {
    total-projects: uint,
    successful-projects: uint,
    failed-projects: uint,
    reputation-score: uint,
    last-updated: uint
  }
)

;; Individual project tracking
(define-map projects
  { project-id: uint }
  {
    operator: principal,
    project-name: (string-ascii 64),
    status: uint,
    launch-block: uint,
    completion-block: (optional uint)
  }
)

;; Project counter
(define-data-var next-project-id uint u1)

;; Authorized evaluators who can update project outcomes
(define-map authorized-evaluators
  { evaluator: principal }
  { authorized: bool }
)

;; public functions

;; Initialize an operator (can be called by anyone to register themselves)
(define-public (register-operator)
  (let ((caller tx-sender))
    (map-set operator-reputation
      { operator: caller }
      {
        total-projects: u0,
        successful-projects: u0,
        failed-projects: u0,
        reputation-score: u50, ;; Start with neutral score
        last-updated: block-height
      }
    )
    (ok true)
  )
)

;; Add a new project for an operator
(define-public (add-project (operator principal) (project-name (string-ascii 64)))
  (let (
    (project-id (var-get next-project-id))
    (operator-data (unwrap! (map-get? operator-reputation { operator: operator }) ERR_OPERATOR_NOT_FOUND))
  )
    ;; Add the project (we'll allow duplicate names for simplicity)
    (map-set projects
      { project-id: project-id }
      {
        operator: operator,
        project-name: project-name,
        status: PROJECT_STATUS_PENDING,
        launch-block: block-height,
        completion-block: none
      }
    )

    ;; Update operator's total project count
    (map-set operator-reputation
      { operator: operator }
      (merge operator-data {
        total-projects: (+ (get total-projects operator-data) u1),
        last-updated: block-height
      })
    )

    ;; Increment project counter
    (var-set next-project-id (+ project-id u1))

    (ok project-id)
  )
)

;; Update project outcome (only authorized evaluators can call this)
(define-public (update-project-outcome (project-id uint) (successful bool))
  (let (
    (project-data (unwrap! (map-get? projects { project-id: project-id }) ERR_PROJECT_NOT_FOUND))
    (operator (get operator project-data))
    (operator-data (unwrap! (map-get? operator-reputation { operator: operator }) ERR_OPERATOR_NOT_FOUND))
    (evaluator-auth (default-to false (get authorized (map-get? authorized-evaluators { evaluator: tx-sender }))))
  )
    ;; Check authorization
    (asserts! (or (is-eq tx-sender (var-get contract-owner)) evaluator-auth) ERR_NOT_AUTHORIZED)

    ;; Update project status
    (map-set projects
      { project-id: project-id }
      (merge project-data {
        status: (if successful PROJECT_STATUS_SUCCESSFUL PROJECT_STATUS_FAILED),
        completion-block: (some block-height)
      })
    )

    ;; Update operator reputation
    (let (
      (new-successful (if successful (+ (get successful-projects operator-data) u1) (get successful-projects operator-data)))
      (new-failed (if successful (get failed-projects operator-data) (+ (get failed-projects operator-data) u1)))
      (new-reputation (calculate-reputation-score new-successful (get total-projects operator-data)))
    )
      (map-set operator-reputation
        { operator: operator }
        (merge operator-data {
          successful-projects: new-successful,
          failed-projects: new-failed,
          reputation-score: new-reputation,
          last-updated: block-height
        })
      )
    )

    (ok true)
  )
)

;; Authorize an evaluator (only contract owner)
(define-public (authorize-evaluator (evaluator principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (map-set authorized-evaluators
      { evaluator: evaluator }
      { authorized: true }
    )
    (ok true)
  )
)

;; Revoke evaluator authorization (only contract owner)
(define-public (revoke-evaluator (evaluator principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (map-set authorized-evaluators
      { evaluator: evaluator }
      { authorized: false }
    )
    (ok true)
  )
)

;; read only functions

;; Get operator reputation data
(define-read-only (get-operator-reputation (operator principal))
  (map-get? operator-reputation { operator: operator })
)

;; Get project details
(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

;; Get operator's success rate as percentage
(define-read-only (get-success-rate (operator principal))
  (match (map-get? operator-reputation { operator: operator })
    operator-data
    (let (
      (total (get total-projects operator-data))
      (successful (get successful-projects operator-data))
    )
      (if (is-eq total u0)
        u0
        (* (/ successful total) u100)
      )
    )
    u0
  )
)

;; Check if an evaluator is authorized
(define-read-only (is-authorized-evaluator (evaluator principal))
  (default-to false (get authorized (map-get? authorized-evaluators { evaluator: evaluator })))
)

;; Get contract owner
(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

;; Get next project ID
(define-read-only (get-next-project-id)
  (var-get next-project-id)
)

;; private functions

;; Calculate reputation score based on success rate
(define-private (calculate-reputation-score (successful-projects uint) (total-projects uint))
  (if (is-eq total-projects u0)
    u50 ;; Default neutral score for new operators
    (let (
      (success-rate (* (/ successful-projects total-projects) u100))
    )
      ;; Ensure score is within bounds
      (if (> success-rate MAX_REPUTATION_SCORE)
        MAX_REPUTATION_SCORE
        (if (< success-rate MIN_REPUTATION_SCORE)
          MIN_REPUTATION_SCORE
          success-rate
        )
      )
    )
  )
)

