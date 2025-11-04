(define-fungible-token recycling-rewards)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-balance (err u101))
(define-constant err-product-not-found (err u102))
(define-constant err-listing-not-found (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-invalid-price (err u105))
(define-constant err-listing-inactive (err u106))
(define-constant err-escrow-not-found (err u107))
(define-constant err-already-completed (err u108))
(define-constant err-not-buyer (err u109))
(define-constant err-not-manufacturer (err u110))
(define-constant err-invalid-condition (err u111))
(define-constant err-already-verified (err u112))
(define-constant err-not-verified (err u113))
(define-constant err-invalid-amount (err u114))
(define-constant err-manufacturer-exists (err u115))
(define-constant err-manufacturer-not-found (err u116))
(define-constant err-already-released (err u117))
(define-constant err-dispute-exists (err u118))
(define-constant err-warranty-expired (err u119))
(define-constant err-warranty-not-found (err u120))
(define-constant err-product-history-not-found (err u121))

(define-constant condition-excellent u5)
(define-constant condition-good u4)
(define-constant condition-fair u3)
(define-constant condition-poor u2)
(define-constant condition-broken u1)

(define-constant escrow-fee-rate u25)
(define-constant recycling-bonus-base u1000)
(define-constant manufacturer-incentive-rate u50)

(define-data-var listing-id-nonce uint u0)
(define-data-var escrow-id-nonce uint u0)
(define-data-var total-recycled-items uint u0)
(define-data-var platform-fees-collected uint u0)
(define-data-var total-rewards-distributed uint u0)
(define-data-var warranty-id-nonce uint u0)
(define-data-var product-history-id-nonce uint u0)

(define-map manufacturers principal {
    name: (string-ascii 50),
    verified: bool,
    products-bought: uint,
    total-spent: uint,
    sustainability-score: uint,
    registered-at: uint
})

(define-map product-listings uint {
    seller: principal,
    manufacturer: principal,
    product-name: (string-ascii 100),
    product-category: (string-ascii 30),
    original-purchase-date: uint,
    condition: uint,
    price: uint,
    buyback-price: uint,
    listed-at: uint,
    is-active: bool,
    escrow-id: (optional uint)
})

(define-map escrow-contracts uint {
    listing-id: uint,
    buyer: principal,
    seller: principal,
    amount: uint,
    fee: uint,
    created-at: uint,
    released-at: (optional uint),
    status: (string-ascii 20),
    condition-verified: bool,
    dispute-reason: (optional (string-ascii 200))
})

(define-map user-metrics principal {
    items-sold: uint,
    items-bought: uint,
    total-earned: uint,
    total-spent: uint,
    recycling-rewards: uint,
    reputation-score: uint,
    last-transaction: uint
})

(define-map recycling-certificates uint {
    user: principal,
    manufacturer: principal,
    product-name: (string-ascii 100),
    recycled-at: uint,
    environmental-impact: uint,
    certificate-hash: (buff 32)
})

(define-map product-categories (string-ascii 30) {
    recycling-multiplier: uint,
    active-listings: uint,
    total-recycled: uint
})

(define-map product-warranties uint {
    listing-id: uint,
    manufacturer: principal,
    warranty-duration-blocks: uint,
    coverage-details: (string-ascii 200),
    issued-at: uint,
    expires-at: uint,
    is-active: bool,
    claim-count: uint,
    max-claims: uint
})

(define-map product-lifecycle-history uint {
    listing-id: uint,
    product-name: (string-ascii 100),
    owner: principal,
    previous-owner: (optional principal),
    transfer-type: (string-ascii 20),
    transfer-date: uint,
    condition-at-transfer: uint,
    price-at-transfer: uint,
    warranty-id: (optional uint),
    cycle-number: uint
})

(define-public (register-manufacturer (name (string-ascii 50)))
    (let ((caller tx-sender))
        (asserts! (is-none (map-get? manufacturers caller)) err-manufacturer-exists)
        (map-set manufacturers caller {
            name: name,
            verified: false,
            products-bought: u0,
            total-spent: u0,
            sustainability-score: u100,
            registered-at: stacks-block-height
        })
        (ok true)))

(define-public (verify-manufacturer (manufacturer principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (let ((manufacturer-data (unwrap! (map-get? manufacturers manufacturer) err-manufacturer-not-found)))
            (map-set manufacturers manufacturer 
                (merge manufacturer-data { verified: true }))
            (ok true))))

(define-public (list-product 
    (manufacturer principal)
    (product-name (string-ascii 100))
    (category (string-ascii 30))
    (original-purchase-date uint)
    (condition uint)
    (price uint))
    (let 
        ((listing-id (+ (var-get listing-id-nonce) u1))
         (manufacturer-data (unwrap! (map-get? manufacturers manufacturer) err-manufacturer-not-found)))
        (asserts! (get verified manufacturer-data) err-not-verified)
        (asserts! (> price u0) err-invalid-price)
        (asserts! (and (>= condition u1) (<= condition u5)) err-invalid-condition)
        
        (let ((buyback-price (calculate-buyback-price price condition)))
            (map-set product-listings listing-id {
                seller: tx-sender,
                manufacturer: manufacturer,
                product-name: product-name,
                product-category: category,
                original-purchase-date: original-purchase-date,
                condition: condition,
                price: price,
                buyback-price: buyback-price,
                listed-at: stacks-block-height,
                is-active: true,
                escrow-id: none
            })
            (var-set listing-id-nonce listing-id)
            (update-category-stats category true)
            (ok listing-id))))

(define-public (initiate-buyback (listing-id uint))
    (let 
        ((listing (unwrap! (map-get? product-listings listing-id) err-listing-not-found))
         (escrow-id (+ (var-get escrow-id-nonce) u1)))
        
        (asserts! (get is-active listing) err-listing-inactive)
        (asserts! (is-eq tx-sender (get manufacturer listing)) err-not-manufacturer)
        
        (let ((escrow-fee (/ (* (get buyback-price listing) escrow-fee-rate) u1000)))
            (try! (stx-transfer? (+ (get buyback-price listing) escrow-fee) tx-sender (as-contract tx-sender)))
            
            (map-set escrow-contracts escrow-id {
                listing-id: listing-id,
                buyer: tx-sender,
                seller: (get seller listing),
                amount: (get buyback-price listing),
                fee: escrow-fee,
                created-at: stacks-block-height,
                released-at: none,
                status: "pending",
                condition-verified: false,
                dispute-reason: none
            })
            
            (map-set product-listings listing-id 
                (merge listing { 
                    is-active: false,
                    escrow-id: (some escrow-id)
                }))
            
            (var-set escrow-id-nonce escrow-id)
            (var-set platform-fees-collected (+ (var-get platform-fees-collected) escrow-fee))
            (ok escrow-id))))

(define-public (confirm-condition (escrow-id uint) (condition-met bool))
    (let ((escrow (unwrap! (map-get? escrow-contracts escrow-id) err-escrow-not-found)))
        (asserts! (is-eq tx-sender (get buyer escrow)) err-not-buyer)
        (asserts! (is-eq (get status escrow) "pending") err-already-completed)
        
        (if condition-met
            (begin
                (map-set escrow-contracts escrow-id 
                    (merge escrow { 
                        condition-verified: true,
                        status: "verified"
                    }))
                (ok true))
            (begin
                (map-set escrow-contracts escrow-id 
                    (merge escrow { 
                        status: "disputed",
                        dispute-reason: (some "Condition not as described")
                    }))
                (ok false)))))

(define-public (release-payment (escrow-id uint))
    (let 
        ((escrow (unwrap! (map-get? escrow-contracts escrow-id) err-escrow-not-found))
         (listing (unwrap! (map-get? product-listings (get listing-id escrow)) err-listing-not-found)))
        
        (asserts! (get condition-verified escrow) err-not-verified)
        (asserts! (is-eq (get status escrow) "verified") err-already-released)
        
        (try! (as-contract (stx-transfer? (get amount escrow) tx-sender (get seller escrow))))
        
        (map-set escrow-contracts escrow-id 
            (merge escrow { 
                released-at: (some stacks-block-height),
                status: "completed"
            }))
        
        (let ((rewards (calculate-recycling-rewards (get condition listing) (get product-category listing))))
            (try! (ft-mint? recycling-rewards rewards (get seller escrow)))
            (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) rewards))
            
            (update-user-metrics (get seller escrow) true (get amount escrow) rewards)
            (update-user-metrics (get buyer escrow) false (get amount escrow) u0)
            (update-manufacturer-metrics (get buyer escrow) (get amount escrow))
            
            (var-set total-recycled-items (+ (var-get total-recycled-items) u1))
            (update-category-stats (get product-category listing) false)
            
            (ok true))))

(define-public (dispute-escrow (escrow-id uint) (reason (string-ascii 200)))
    (let ((escrow (unwrap! (map-get? escrow-contracts escrow-id) err-escrow-not-found)))
        (asserts! (or (is-eq tx-sender (get buyer escrow)) (is-eq tx-sender (get seller escrow))) err-unauthorized)
        (asserts! (not (is-eq (get status escrow) "completed")) err-already-completed)
        
        (map-set escrow-contracts escrow-id 
            (merge escrow { 
                status: "disputed",
                dispute-reason: (some reason)
            }))
        (ok true)))

(define-public (resolve-dispute (escrow-id uint) (release-to-seller bool))
    (let ((escrow (unwrap! (map-get? escrow-contracts escrow-id) err-escrow-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-eq (get status escrow) "disputed") err-dispute-exists)
        
        (if release-to-seller
            (try! (as-contract (stx-transfer? (get amount escrow) tx-sender (get seller escrow))))
            (try! (as-contract (stx-transfer? (get amount escrow) tx-sender (get buyer escrow)))))
        
        (map-set escrow-contracts escrow-id 
            (merge escrow { 
                released-at: (some stacks-block-height),
                status: "resolved"
            }))
        (ok true)))

(define-public (mint-initial-rewards (recipient principal) (amount uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ft-mint? recycling-rewards amount recipient)))

(define-private (calculate-buyback-price (original-price uint) (condition uint))
    (let ((base-percentage (if (is-eq condition condition-excellent) u700
                           (if (is-eq condition condition-good) u500
                           (if (is-eq condition condition-fair) u300
                           (if (is-eq condition condition-poor) u150
                           u50))))))
        (/ (* original-price base-percentage) u1000)))

(define-private (calculate-recycling-rewards (condition uint) (category (string-ascii 30)))
    (let ((category-data (default-to { recycling-multiplier: u100, active-listings: u0, total-recycled: u0 } 
                                     (map-get? product-categories category)))
          (condition-bonus (* condition u200)))
        (/ (* recycling-bonus-base (* (get recycling-multiplier category-data) condition-bonus)) u1000)))

(define-private (update-user-metrics (user principal) (is-seller bool) (amount uint) (rewards uint))
    (let ((current-metrics (default-to 
            { items-sold: u0, items-bought: u0, total-earned: u0, total-spent: u0, 
              recycling-rewards: u0, reputation-score: u100, last-transaction: u0 }
            (map-get? user-metrics user))))
        (map-set user-metrics user
            (if is-seller
                (merge current-metrics {
                    items-sold: (+ (get items-sold current-metrics) u1),
                    total-earned: (+ (get total-earned current-metrics) amount),
                    recycling-rewards: (+ (get recycling-rewards current-metrics) rewards),
                    reputation-score: (+ (get reputation-score current-metrics) u10),
                    last-transaction: stacks-block-height
                })
                (merge current-metrics {
                    items-bought: (+ (get items-bought current-metrics) u1),
                    total-spent: (+ (get total-spent current-metrics) amount),
                    last-transaction: stacks-block-height
                })))))

(define-private (update-manufacturer-metrics (manufacturer principal) (amount uint))
    (match (map-get? manufacturers manufacturer)
        manufacturer-data (map-set manufacturers manufacturer
            (merge manufacturer-data {
                products-bought: (+ (get products-bought manufacturer-data) u1),
                total-spent: (+ (get total-spent manufacturer-data) amount),
                sustainability-score: (+ (get sustainability-score manufacturer-data) u5)
            }))
        true))

(define-private (update-category-stats (category (string-ascii 30)) (is-new bool))
    (let ((current-stats (default-to 
            { recycling-multiplier: u100, active-listings: u0, total-recycled: u0 }
            (map-get? product-categories category))))
        (map-set product-categories category
            (if is-new
                (merge current-stats {
                    active-listings: (+ (get active-listings current-stats) u1)
                })
                (merge current-stats {
                    active-listings: (- (get active-listings current-stats) u1),
                    total-recycled: (+ (get total-recycled current-stats) u1)
                })))))

(define-read-only (get-listing (listing-id uint))
    (map-get? product-listings listing-id))

(define-read-only (get-escrow (escrow-id uint))
    (map-get? escrow-contracts escrow-id))

(define-read-only (get-manufacturer (manufacturer principal))
    (map-get? manufacturers manufacturer))

(define-read-only (get-user-metrics (user principal))
    (map-get? user-metrics user))

(define-read-only (get-platform-stats)
    (ok {
        total-recycled: (var-get total-recycled-items),
        fees-collected: (var-get platform-fees-collected),
        rewards-distributed: (var-get total-rewards-distributed),
        active-listings: (var-get listing-id-nonce)
    }))

(define-read-only (get-recycling-reward-balance (account principal))
    (ok (ft-get-balance recycling-rewards account)))

(define-read-only (calculate-estimated-buyback (price uint) (condition uint))
    (ok (calculate-buyback-price price condition)))

(define-public (issue-warranty 
    (listing-id uint)
    (duration-blocks uint)
    (coverage (string-ascii 200))
    (max-claims uint))
    (let 
        ((listing (unwrap! (map-get? product-listings listing-id) err-listing-not-found))
         (warranty-id (+ (var-get warranty-id-nonce) u1))
         (manufacturer-data (unwrap! (map-get? manufacturers tx-sender) err-manufacturer-not-found)))
        
        (asserts! (is-eq tx-sender (get manufacturer listing)) err-not-manufacturer)
        (asserts! (get verified manufacturer-data) err-not-verified)
        (asserts! (> duration-blocks u0) err-invalid-amount)
        (asserts! (> max-claims u0) err-invalid-amount)
        
        (let ((expiry-block (+ stacks-block-height duration-blocks)))
            (map-set product-warranties warranty-id {
                listing-id: listing-id,
                manufacturer: tx-sender,
                warranty-duration-blocks: duration-blocks,
                coverage-details: coverage,
                issued-at: stacks-block-height,
                expires-at: expiry-block,
                is-active: true,
                claim-count: u0,
                max-claims: max-claims
            })
            
            (var-set warranty-id-nonce warranty-id)
            (ok warranty-id))))

(define-public (record-lifecycle-event 
    (listing-id uint)
    (transfer-type (string-ascii 20))
    (previous-owner-opt (optional principal))
    (warranty-id-opt (optional uint)))
    (let 
        ((listing (unwrap! (map-get? product-listings listing-id) err-listing-not-found))
         (history-id (+ (var-get product-history-id-nonce) u1))
         (previous-history (get-latest-lifecycle-entry listing-id))
         (default-history { listing-id: u0, product-name: "", owner: tx-sender, previous-owner: none, 
                           transfer-type: "", transfer-date: u0, condition-at-transfer: u0, 
                           price-at-transfer: u0, warranty-id: none, cycle-number: u0 })
         (cycle-num (+ (get cycle-number (default-to default-history previous-history)) u1)))
        
        (map-set product-lifecycle-history history-id {
            listing-id: listing-id,
            product-name: (get product-name listing),
            owner: tx-sender,
            previous-owner: previous-owner-opt,
            transfer-type: transfer-type,
            transfer-date: stacks-block-height,
            condition-at-transfer: (get condition listing),
            price-at-transfer: (get price listing),
            warranty-id: warranty-id-opt,
            cycle-number: cycle-num
        })
        
        (var-set product-history-id-nonce history-id)
        (ok history-id)))

(define-public (claim-warranty (warranty-id uint))
    (let ((warranty (unwrap! (map-get? product-warranties warranty-id) err-warranty-not-found)))
        (asserts! (get is-active warranty) err-warranty-expired)
        (asserts! (<= stacks-block-height (get expires-at warranty)) err-warranty-expired)
        (asserts! (< (get claim-count warranty) (get max-claims warranty)) err-invalid-amount)
        
        (map-set product-warranties warranty-id 
            (merge warranty {
                claim-count: (+ (get claim-count warranty) u1)
            }))
        (ok true)))

(define-public (deactivate-warranty (warranty-id uint))
    (let ((warranty (unwrap! (map-get? product-warranties warranty-id) err-warranty-not-found)))
        (asserts! (is-eq tx-sender (get manufacturer warranty)) err-not-manufacturer)
        (map-set product-warranties warranty-id 
            (merge warranty { is-active: false }))
        (ok true)))

(define-read-only (get-warranty (warranty-id uint))
    (map-get? product-warranties warranty-id))

(define-read-only (get-lifecycle-history (history-id uint))
    (map-get? product-lifecycle-history history-id))

(define-read-only (check-warranty-status (warranty-id uint))
    (match (map-get? product-warranties warranty-id)
        warranty (ok {
            is-valid: (and (get is-active warranty) (<= stacks-block-height (get expires-at warranty))),
            claims-remaining: (- (get max-claims warranty) (get claim-count warranty)),
            blocks-until-expiry: (if (> (get expires-at warranty) stacks-block-height)
                                    (- (get expires-at warranty) stacks-block-height)
                                    u0)
        })
        err-warranty-not-found))

(define-private (get-latest-lifecycle-entry (listing-id uint))
    (map-get? product-lifecycle-history (var-get product-history-id-nonce)))

