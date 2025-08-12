;; BlockDividend - Advanced Yield Distribution Protocol
;; Implements stratified reward mechanisms, decentralized governance, and yield optimization

;; Authority Constants
(define-constant protocol-guardian tx-sender)
(define-constant err-guardian-restricted (err u100))
(define-constant err-capital-shortage (err u101))
(define-constant err-inactive-participant (err u102))
(define-constant err-yield-unavailable (err u103))
(define-constant err-stratum-invalid (err u104))
(define-constant err-referendum-inactive (err u105))
(define-constant err-ballot-cast (err u106))
(define-constant err-withdrawal-locked (err u107))

;; Capital Stratification Thresholds (in STX)
(define-constant bronze-threshold u100000000) ;; 100 STX
(define-constant silver-threshold u1000000000) ;; 1,000 STX
(define-constant gold-threshold u10000000000) ;; 10,000 STX

;; Yield Enhancement Coefficients (basis points)
(define-constant bronze-coefficient u1000) ;; 1.0x
(define-constant silver-coefficient u1250) ;; 1.25x
(define-constant gold-coefficient u1500) ;; 1.5x

;; Protocol Temporal Controls
(define-constant liquidity-freeze-cycles u100) ;; Block cycles between withdrawals
(define-constant referendum-duration u1440) ;; ~10 days in blocks

;; Protocol State Variables
(define-data-var aggregate-capital uint u0)
(define-data-var protocol-operational bool true)
(define-data-var distribution-epoch uint u0)
(define-data-var accumulated-yield uint u0)
(define-data-var referendum-counter uint u0)
(define-data-var market-valuation uint u0)

;; Participant Data Structures
(define-map participant-holdings principal uint)
(define-map earned-dividends principal uint)
(define-map capital-stratum principal uint)
(define-map epoch-distributions uint uint)
(define-map network-incentives {sponsor: principal, beneficiary: principal} uint)
(define-map withdrawal-timestamps principal uint)
(define-map governance-referendums uint {
    initiator: principal,
    activation-block: uint,
    expiration-block: uint,
    proposition: (string-utf8 256),
    status: bool
})

;; Governance Participation Maps
(define-map referendum-ballots {referendum: uint, participant: principal} bool)
(define-map referendum-tallies uint {affirmative: uint, negative: uint})

;; Query Functions
(define-read-only (get-participant-holdings (participant principal))
    (default-to u0 (map-get? participant-holdings participant))
)

(define-read-only (get-earned-dividends (participant principal))
    (default-to u0 (map-get? earned-dividends participant))
)

(define-read-only (get-capital-stratum (participant principal))
    (default-to u1 (map-get? capital-stratum participant))
)

;; Network Incentive System
(define-public (register-network-incentive (sponsor principal))
    (let (
        (beneficiary tx-sender)
        (incentive-allocation (/ (var-get aggregate-capital) u100)) ;; 1% allocation
    )
    (map-set network-incentives {sponsor: sponsor, beneficiary: beneficiary} incentive-allocation)
    (ok incentive-allocation))
)

(define-read-only (get-network-incentive (sponsor principal) (beneficiary principal))
    (default-to u0 (map-get? network-incentives {sponsor: sponsor, beneficiary: beneficiary}))
)

;; Stratified Capital Deployment
(define-public (deploy-capital (allocation uint))
    (let (
        (existing-holdings (get-participant-holdings tx-sender))
        (updated-holdings (+ existing-holdings allocation))
        (assigned-stratum (calculate-stratum updated-holdings))
    )
    (asserts! (>= allocation bronze-threshold) (err u108))
    (try! (stx-transfer? allocation tx-sender (as-contract tx-sender)))
    
    ;; Update participant records
    (map-set participant-holdings tx-sender updated-holdings)
    (map-set capital-stratum tx-sender assigned-stratum)
    
    ;; Update protocol aggregate
    (var-set aggregate-capital (+ (var-get aggregate-capital) allocation))
    
    (ok allocation))
)

;; Capital Withdrawal with Temporal Lock
(define-public (withdraw-capital (withdrawal-amount uint))
    (let (
        (current-holdings (get-participant-holdings tx-sender))
        (last-withdrawal (default-to u0 (map-get? withdrawal-timestamps tx-sender)))
        (current-block stacks-block-height)
    )
    (asserts! (>= current-holdings withdrawal-amount) err-capital-shortage)
    (asserts! (>= (- current-block last-withdrawal) liquidity-freeze-cycles) err-withdrawal-locked)
    
    ;; Execute capital transfer
    (try! (as-contract (stx-transfer? withdrawal-amount (as-contract tx-sender) tx-sender)))
    
    ;; Update participant records
    (map-set participant-holdings tx-sender (- current-holdings withdrawal-amount))
    (map-set withdrawal-timestamps tx-sender current-block)
    
    ;; Update protocol aggregate
    (var-set aggregate-capital (- (var-get aggregate-capital) withdrawal-amount))
    
    (ok withdrawal-amount))
)

;; Capital Stratum Classification
(define-private (calculate-stratum (holdings uint))
    (if (>= holdings gold-threshold)
        u3
        (if (>= holdings silver-threshold)
            u2
            u1))
)

;; Decentralized Governance System
(define-public (initiate-referendum (proposition (string-utf8 256)))
    (let (
        (referendum-id (var-get referendum-counter))
        (activation-block stacks-block-height)
        (expiration-block (+ activation-block referendum-duration))
        (participant-holdings (get-participant-holdings tx-sender))
    )
    (asserts! (>= participant-holdings silver-threshold) (err u109))
    
    ;; Create referendum record
    (map-set governance-referendums referendum-id {
        initiator: tx-sender,
        activation-block: activation-block,
        expiration-block: expiration-block,
        proposition: proposition,
        status: true
    })
    
    ;; Initialize vote tallies
    (map-set referendum-tallies referendum-id {affirmative: u0, negative: u0})
    
    ;; Increment referendum counter
    (var-set referendum-counter (+ referendum-id u1))
    
    (ok referendum-id))
)

(define-public (cast-ballot (referendum-id uint) (ballot-choice bool))
    (let (
        (referendum (unwrap! (map-get? governance-referendums referendum-id) err-referendum-inactive))
        (voting-weight (calculate-voting-weight tx-sender))
        (current-tallies (default-to {affirmative: u0, negative: u0} (map-get? referendum-tallies referendum-id)))
    )
    (asserts! (not (default-to false (map-get? referendum-ballots {referendum: referendum-id, participant: tx-sender}))) err-ballot-cast)
    (asserts! (and (>= stacks-block-height (get activation-block referendum)) (<= stacks-block-height (get expiration-block referendum))) err-referendum-inactive)
    
    ;; Record ballot
    (map-set referendum-ballots {referendum: referendum-id, participant: tx-sender} ballot-choice)
    
    ;; Update tallies
    (if ballot-choice
        (map-set referendum-tallies referendum-id 
            {affirmative: (+ (get affirmative current-tallies) voting-weight), 
             negative: (get negative current-tallies)})
        (map-set referendum-tallies referendum-id 
            {affirmative: (get affirmative current-tallies), 
             negative: (+ (get negative current-tallies) voting-weight)}))
    
    (ok true))
)

;; Voting Weight Calculation
(define-private (calculate-voting-weight (participant principal))
    (let (
        (holdings (get-participant-holdings participant))
        (stratum (default-to u1 (map-get? capital-stratum participant)))
    )
    (/ (* holdings stratum) u100)) ;; Weight = holdings * stratum / 100
)

;; Market Valuation Oracle
(define-public (update-market-valuation (new-valuation uint))
    (begin
        (asserts! (is-eq tx-sender protocol-guardian) err-guardian-restricted)
        (var-set market-valuation new-valuation)
        (ok new-valuation))
)

;; Stratified Dividend Computation
(define-public (compute-dividends (participant principal))
    (let (
        (participant-holdings (get-participant-holdings participant))
        (participant-stratum (default-to u1 (map-get? capital-stratum participant)))
        (stratum-multiplier (get-stratum-multiplier participant-stratum))
        (total-capital (var-get aggregate-capital))
        (epoch-yield (default-to u0 (map-get? epoch-distributions (- (var-get distribution-epoch) u1))))
    )
    (if (is-eq total-capital u0)
        (ok u0)
        (ok (/ (* (* participant-holdings epoch-yield) stratum-multiplier) (* total-capital u1000))))
))

(define-private (get-stratum-multiplier (stratum uint))
    (if (is-eq stratum u3)
        gold-coefficient
        (if (is-eq stratum u2)
            silver-coefficient
            bronze-coefficient))
)

;; Protocol Emergency Controls
(define-data-var emergency-activation uint u0)
(define-constant temporal-delay u144) ;; ~24 hours in blocks

(define-public (activate-emergency-protocol)
    (begin
        (asserts! (is-eq tx-sender protocol-guardian) err-guardian-restricted)
        (var-set emergency-activation (+ stacks-block-height temporal-delay))
        (ok stacks-block-height))
)

(define-public (execute-emergency-recovery)
    (begin
        (asserts! (is-eq tx-sender protocol-guardian) err-guardian-restricted)
        (asserts! (>= stacks-block-height (var-get emergency-activation)) (err u110))
        (let (
            (protocol-balance (stx-get-balance (as-contract tx-sender)))
        )
        (try! (as-contract (stx-transfer? protocol-balance (as-contract tx-sender) protocol-guardian)))
        (ok protocol-balance)))
)

;; Dividend Distribution Mechanism
(define-public (distribute-epoch-dividends (epoch-yield uint))
    (begin
        (asserts! (is-eq tx-sender protocol-guardian) err-guardian-restricted)
        (let (
            (current-epoch (var-get distribution-epoch))
        )
        (map-set epoch-distributions current-epoch epoch-yield)
        (var-set distribution-epoch (+ current-epoch u1))
        (var-set accumulated-yield (+ (var-get accumulated-yield) epoch-yield))
        (ok current-epoch)))
)

;; Participant Dividend Claim
(define-public (claim-dividends)
    (let (
        (participant tx-sender)
        (computed-dividends (unwrap! (compute-dividends participant) err-yield-unavailable))
    )
    (asserts! (> computed-dividends u0) err-yield-unavailable)
    
    ;; Transfer dividends to participant
    (try! (as-contract (stx-transfer? computed-dividends (as-contract tx-sender) participant)))
    
    ;; Update earned dividends record
    (map-set earned-dividends participant 
        (+ (default-to u0 (map-get? earned-dividends participant)) computed-dividends))
    
    (ok computed-dividends))
)