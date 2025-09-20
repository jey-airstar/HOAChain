
;; title: HOAChain
;; version: 1.0.0
;; summary: Transparent voting system for residential association bylaws and community decisions
;; description: A decentralized voting platform that enables HOA members to propose, vote on, and track community decisions with full transparency

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_VOTED (err u102))
(define-constant ERR_VOTING_ENDED (err u103))
(define-constant ERR_VOTING_NOT_STARTED (err u104))
(define-constant ERR_INVALID_MEMBER (err u105))
(define-constant ERR_PROPOSAL_ACTIVE (err u106))
(define-constant ERR_INSUFFICIENT_VOTES (err u107))

;; Data Variables
(define-data-var proposal-counter uint u0)
(define-data-var total-members uint u0)

;; Data Maps
;; HOA member registry
(define-map hoa-members principal bool)

;; Proposals storage
(define-map proposals uint {
    title: (string-utf8 100),
    description: (string-utf8 500),
    proposer: principal,
    start-block: uint,
    end-block: uint,
    votes-for: uint,
    votes-against: uint,
    status: (string-ascii 20), ;; "active", "passed", "rejected", "expired"
    category: (string-ascii 30) ;; "bylaw", "budget", "maintenance", "policy", "other"
})

;; Track individual votes to prevent double voting
(define-map votes {proposal-id: uint, voter: principal} bool)

;; Member voting power (default 1, can be adjusted for different member types)
(define-map member-voting-power principal uint)

;; Public Functions

;; Initialize contract with first HOA member (contract deployer)
(define-public (initialize)
    (begin
        (map-set hoa-members CONTRACT_OWNER true)
        (map-set member-voting-power CONTRACT_OWNER u1)
        (var-set total-members u1)
        (ok true)
    )
)

;; Add a new HOA member (only existing members can add new members)
(define-public (add-member (new-member principal))
    (begin
        (asserts! (is-hoa-member tx-sender) ERR_UNAUTHORIZED)
        (asserts! (not (is-hoa-member new-member)) ERR_UNAUTHORIZED)
        (map-set hoa-members new-member true)
        (map-set member-voting-power new-member u1)
        (var-set total-members (+ (var-get total-members) u1))
        (ok true)
    )
)

;; Remove an HOA member (only contract owner can remove members)
(define-public (remove-member (member principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-hoa-member member) ERR_INVALID_MEMBER)
        (map-delete hoa-members member)
        (map-delete member-voting-power member)
        (var-set total-members (- (var-get total-members) u1))
        (ok true)
    )
)

;; Create a new proposal
(define-public (create-proposal
    (title (string-utf8 100))
    (description (string-utf8 500))
    (voting-duration uint)
    (category (string-ascii 30)))
    (let
        ((proposal-id (+ (var-get proposal-counter) u1))
         (start-block block-height)
         (end-block (+ block-height voting-duration)))
        (begin
            (asserts! (is-hoa-member tx-sender) ERR_UNAUTHORIZED)
            (map-set proposals proposal-id {
                title: title,
                description: description,
                proposer: tx-sender,
                start-block: start-block,
                end-block: end-block,
                votes-for: u0,
                votes-against: u0,
                status: "active",
                category: category
            })
            (var-set proposal-counter proposal-id)
            (ok proposal-id)
        )
    )
)

;; Vote on a proposal
(define-public (vote (proposal-id uint) (vote-for bool))
    (let
        ((proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
         (voter-power (default-to u1 (map-get? member-voting-power tx-sender))))
        (begin
            (asserts! (is-hoa-member tx-sender) ERR_UNAUTHORIZED)
            (asserts! (>= block-height (get start-block proposal)) ERR_VOTING_NOT_STARTED)
            (asserts! (<= block-height (get end-block proposal)) ERR_VOTING_ENDED)
            (asserts! (is-eq (get status proposal) "active") ERR_VOTING_ENDED)
            (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: tx-sender})) ERR_ALREADY_VOTED)

            ;; Record the vote
            (map-set votes {proposal-id: proposal-id, voter: tx-sender} vote-for)

            ;; Update vote counts
            (if vote-for
                (map-set proposals proposal-id
                    (merge proposal {votes-for: (+ (get votes-for proposal) voter-power)}))
                (map-set proposals proposal-id
                    (merge proposal {votes-against: (+ (get votes-against proposal) voter-power)}))
            )
            (ok true)
        )
    )
)

;; Finalize a proposal (can be called by anyone after voting period ends)
(define-public (finalize-proposal (proposal-id uint))
    (let
        ((proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
         (total-votes (+ (get votes-for proposal) (get votes-against proposal)))
         (required-quorum (/ (var-get total-members) u2))) ;; 50% quorum
        (begin
            (asserts! (> block-height (get end-block proposal)) ERR_VOTING_NOT_STARTED)
            (asserts! (is-eq (get status proposal) "active") ERR_PROPOSAL_ACTIVE)

            ;; Check if quorum was met and determine result
            (if (>= total-votes required-quorum)
                (if (> (get votes-for proposal) (get votes-against proposal))
                    (map-set proposals proposal-id (merge proposal {status: "passed"}))
                    (map-set proposals proposal-id (merge proposal {status: "rejected"})))
                (map-set proposals proposal-id (merge proposal {status: "expired"}))
            )
            (ok true)
        )
    )
)

;; Update member voting power (only contract owner)
(define-public (update-voting-power (member principal) (new-power uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-hoa-member member) ERR_INVALID_MEMBER)
        (map-set member-voting-power member new-power)
        (ok true)
    )
)

;; Read-only Functions

;; Check if an address is an HOA member
(define-read-only (is-hoa-member (member principal))
    (default-to false (map-get? hoa-members member))
)

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals proposal-id)
)

;; Get total number of proposals
(define-read-only (get-proposal-count)
    (var-get proposal-counter)
)

;; Get total number of members
(define-read-only (get-member-count)
    (var-get total-members)
)

;; Check if a member has voted on a proposal
(define-read-only (has-voted (proposal-id uint) (voter principal))
    (is-some (map-get? votes {proposal-id: proposal-id, voter: voter}))
)

;; Get member's voting power
(define-read-only (get-voting-power (member principal))
    (default-to u0 (map-get? member-voting-power member))
)

;; Get vote details for a specific voter and proposal
(define-read-only (get-vote (proposal-id uint) (voter principal))
    (map-get? votes {proposal-id: proposal-id, voter: voter})
)

;; Check if proposal is active
(define-read-only (is-proposal-active (proposal-id uint))
    (match (map-get? proposals proposal-id)
        proposal (and
            (is-eq (get status proposal) "active")
            (>= block-height (get start-block proposal))
            (<= block-height (get end-block proposal)))
        false
    )
)

;; Get contract owner
(define-read-only (get-contract-owner)
    CONTRACT_OWNER
)

;; Private Functions

;; Helper function to calculate quorum (can be made more sophisticated)
(define-private (calculate-quorum)
    (/ (var-get total-members) u2)
)
