;; Goal Manager Smart Contract - Professional/Business Theme
;; Set goals, achieve milestones, earn certifications

;; Constants
(define-constant contract-administrator tx-sender)
(define-constant err-admin-only (err u100))
(define-constant err-goal-not-found (err u101))
(define-constant err-goal-already-achieved (err u102))
(define-constant err-unauthorized-user (err u103))
(define-constant err-invalid-goal (err u104))

;; Data Variables
(define-data-var goal-index uint u0)
(define-data-var certification-index uint u0)

;; Data Maps
;; Store goal information
(define-map goals 
    { goal-id: uint, user: principal }
    { 
        goal-title: (string-utf8 256),
        milestone-description: (string-utf8 1024),
        achieved: bool,
        set-date: uint,
        achieved-date: (optional uint)
    }
)

;; Track user performance metrics
(define-map user-metrics
    principal
    {
        total-goals: uint,
        achieved-goals: uint,
        pending-goals: uint
    }
)

;; NFT Professional Certifications
(define-non-fungible-token professional-certification uint)

;; Map to track certifications earned
(define-map certification-registry
    { user: principal, certification-type: (string-ascii 50) }
    { earned: bool, earned-date: uint }
)

;; Helper Functions
(define-private (generate-next-goal-id)
    (let ((current-index (var-get goal-index)))
        (var-set goal-index (+ current-index u1))
        current-index
    )
)

(define-private (generate-next-certification-id)
    (let ((current-index (var-get certification-index)))
        (var-set certification-index (+ current-index u1))
        current-index
    )
)

;; Read-only Functions
(define-read-only (retrieve-goal (goal-id uint) (user principal))
    (map-get? goals { goal-id: goal-id, user: user })
)

(define-read-only (fetch-user-metrics (user principal))
    (default-to 
        { total-goals: u0, achieved-goals: u0, pending-goals: u0 }
        (map-get? user-metrics user)
    )
)

(define-read-only (check-certification (user principal) (certification-type (string-ascii 50)))
    (default-to 
        { earned: false, earned-date: u0 }
        (map-get? certification-registry { user: user, certification-type: certification-type })
    )
)

;; Private Functions
(define-private (refresh-user-metrics (user principal) (is-new bool) (is-achieved bool))
    (let ((current-metrics (fetch-user-metrics user)))
        (if is-new
            ;; Setting a new goal
            (map-set user-metrics user {
                total-goals: (+ (get total-goals current-metrics) u1),
                achieved-goals: (get achieved-goals current-metrics),
                pending-goals: (+ (get pending-goals current-metrics) u1)
            })
            (if is-achieved
                ;; Achieving a goal
                (map-set user-metrics user {
                    total-goals: (get total-goals current-metrics),
                    achieved-goals: (+ (get achieved-goals current-metrics) u1),
                    pending-goals: (- (get pending-goals current-metrics) u1)
                })
                ;; Removing a goal
                (map-set user-metrics user {
                    total-goals: (get total-goals current-metrics),
                    achieved-goals: (get achieved-goals current-metrics),
                    pending-goals: (- (get pending-goals current-metrics) u1)
                })
            )
        )
    )
)

(define-private (evaluate-and-issue-certifications (user principal))
    (let (
        (metrics (fetch-user-metrics user))
        (achieved (get achieved-goals metrics))
    )
        ;; Evaluate certification eligibility
        (begin
            ;; Starter certification
            (and (is-eq achieved u1) 
                 (not (get earned (check-certification user "goal-starter")))
                 (is-ok (issue-certification user "goal-starter")))
            ;; Bronze certification for 10 goals
            (and (>= achieved u10) 
                 (not (get earned (check-certification user "bronze-achiever")))
                 (is-ok (issue-certification user "bronze-achiever")))
            ;; Silver certification for 50 goals
            (and (>= achieved u50) 
                 (not (get earned (check-certification user "silver-performer")))
                 (is-ok (issue-certification user "silver-performer")))
            ;; Gold certification for 100 goals
            (and (>= achieved u100) 
                 (not (get earned (check-certification user "gold-excellence")))
                 (is-ok (issue-certification user "gold-excellence")))
            true
        )
    )
)

(define-private (issue-certification (user principal) (certification-type (string-ascii 50)))
    (let ((cert-id (generate-next-certification-id)))
        (map-set certification-registry 
            { user: user, certification-type: certification-type }
            { earned: true, earned-date: block-height }
        )
        (nft-mint? professional-certification cert-id user)
    )
)

;; Public Functions
(define-public (set-goal (goal-title (string-utf8 256)) (milestone-description (string-utf8 1024)))
    (let (
        (goal-id (generate-next-goal-id))
        (user tx-sender)
    )
        (if (or (is-eq (len goal-title) u0) (> (len goal-title) u256) (> (len milestone-description) u1024))
            err-invalid-goal
            (begin
                (map-set goals 
                    { goal-id: goal-id, user: user }
                    {
                        goal-title: goal-title,
                        milestone-description: milestone-description,
                        achieved: false,
                        set-date: block-height,
                        achieved-date: none
                    }
                )
                (refresh-user-metrics user true false)
                (ok goal-id)
            )
        )
    )
)

(define-public (achieve-goal (goal-id uint))
    (let (
        (goal-key { goal-id: goal-id, user: tx-sender })
        (goal (map-get? goals goal-key))
    )
        (match goal
            goal-data
            (if (get achieved goal-data)
                err-goal-already-achieved
                (begin
                    (map-set goals goal-key
                        (merge goal-data {
                            achieved: true,
                            achieved-date: (some block-height)
                        })
                    )
                    (refresh-user-metrics tx-sender false true)
                    (evaluate-and-issue-certifications tx-sender)
                    (ok true)
                )
            )
            err-goal-not-found
        )
    )
)

(define-public (remove-goal (goal-id uint))
    (let (
        (goal-key { goal-id: goal-id, user: tx-sender })
        (goal (map-get? goals goal-key))
    )
        (match goal
            goal-data
            (begin
                (map-delete goals goal-key)
                (if (not (get achieved goal-data))
                    (refresh-user-metrics tx-sender false false)
                    true
                )
                (ok true)
            )
            err-goal-not-found
        )
    )
)

;; Revise goal details
(define-public (revise-goal (goal-id uint) (goal-title (string-utf8 256)) (milestone-description (string-utf8 1024)))
    (let (
        (goal-key { goal-id: goal-id, user: tx-sender })
        (goal (map-get? goals goal-key))
    )
        (match goal
            goal-data
            (if (get achieved goal-data)
                err-goal-already-achieved
                (if (or (is-eq (len goal-title) u0) (> (len goal-title) u256) (> (len milestone-description) u1024))
                    err-invalid-goal
                    (begin
                        (map-set goals goal-key
                            (merge goal-data {
                                goal-title: goal-title,
                                milestone-description: milestone-description
                            })
                        )
                        (ok true)
                    )
                )
            )
            err-goal-not-found
        )
    )
)

;; Verify goal existence
(define-read-only (goal-exists (goal-id uint) (user principal))
    (is-some (map-get? goals { goal-id: goal-id, user: user }))
)