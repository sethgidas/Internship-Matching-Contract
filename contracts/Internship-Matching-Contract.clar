(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-STATUS (err u103))
(define-constant ERR-INVALID-PARAMS (err u104))
(define-constant ERR-INSUFFICIENT-REPUTATION (err u105))
(define-constant ERR-NOT-AVAILABLE (err u106))
(define-constant ERR-ALREADY-MATCHED (err u107))

(define-data-var next-applicant-id uint u1)
(define-data-var next-employer-id uint u1)
(define-data-var next-internship-id uint u1)
(define-data-var next-match-id uint u1)

(define-map applicants 
  { applicant-id: uint }
  {
    wallet: principal,
    name: (string-ascii 50),
    skills: (string-ascii 200),
    reputation: uint,
    available: bool,
    registered-at: uint
  }
)

(define-map employers
  { employer-id: uint }
  {
    wallet: principal,
    company: (string-ascii 50),
    industry: (string-ascii 100),
    reputation: uint,
    active: bool,
    registered-at: uint
  }
)

(define-map internships
  { internship-id: uint }
  {
    employer-id: uint,
    title: (string-ascii 100),
    description: (string-ascii 500),
    requirements: (string-ascii 300),
    duration: uint,
    stipend: uint,
    status: (string-ascii 20),
    created-at: uint
  }
)

(define-map matches
  { match-id: uint }
  {
    applicant-id: uint,
    employer-id: uint,
    internship-id: uint,
    status: (string-ascii 20),
    created-at: uint,
    completed-at: (optional uint),
    applicant-rating: (optional uint),
    employer-rating: (optional uint)
  }
)

(define-map applicant-wallet-to-id principal uint)
(define-map employer-wallet-to-id principal uint)

(define-read-only (get-applicant (applicant-id uint))
  (map-get? applicants { applicant-id: applicant-id })
)

(define-read-only (get-employer (employer-id uint))
  (map-get? employers { employer-id: employer-id })
)

(define-read-only (get-internship (internship-id uint))
  (map-get? internships { internship-id: internship-id })
)

(define-read-only (get-match (match-id uint))
  (map-get? matches { match-id: match-id })
)

(define-read-only (get-applicant-by-wallet (wallet principal))
  (match (map-get? applicant-wallet-to-id wallet)
    id (get-applicant id)
    none
  )
)

(define-read-only (get-employer-by-wallet (wallet principal))
  (match (map-get? employer-wallet-to-id wallet)
    id (get-employer id)
    none
  )
)

(define-public (register-applicant (name (string-ascii 50)) (skills (string-ascii 200)))
  (let
    (
      (applicant-id (var-get next-applicant-id))
      (current-block burn-block-height)
    )
    (asserts! (is-none (map-get? applicant-wallet-to-id tx-sender)) ERR-ALREADY-EXISTS)
    (asserts! (> (len name) u0) ERR-INVALID-PARAMS)
    (asserts! (> (len skills) u0) ERR-INVALID-PARAMS)
    
    (map-set applicants
      { applicant-id: applicant-id }
      {
        wallet: tx-sender,
        name: name,
        skills: skills,
        reputation: u50,
        available: true,
        registered-at: current-block
      }
    )
    
    (map-set applicant-wallet-to-id tx-sender applicant-id)
    (var-set next-applicant-id (+ applicant-id u1))
    (ok applicant-id)
  )
)

(define-public (register-employer (company (string-ascii 50)) (industry (string-ascii 100)))
  (let
    (
      (employer-id (var-get next-employer-id))
      (current-block burn-block-height)
    )
    (asserts! (is-none (map-get? employer-wallet-to-id tx-sender)) ERR-ALREADY-EXISTS)
    (asserts! (> (len company) u0) ERR-INVALID-PARAMS)
    (asserts! (> (len industry) u0) ERR-INVALID-PARAMS)
    
    (map-set employers
      { employer-id: employer-id }
      {
        wallet: tx-sender,
        company: company,
        industry: industry,
        reputation: u50,
        active: true,
        registered-at: current-block
      }
    )
    
    (map-set employer-wallet-to-id tx-sender employer-id)
    (var-set next-employer-id (+ employer-id u1))
    (ok employer-id)
  )
)

(define-public (create-internship 
  (title (string-ascii 100)) 
  (description (string-ascii 500))
  (requirements (string-ascii 300))
  (duration uint)
  (stipend uint)
)
  (let
    (
      (internship-id (var-get next-internship-id))
      (employer-id-opt (map-get? employer-wallet-to-id tx-sender))
      (current-block burn-block-height)
    )
    (asserts! (is-some employer-id-opt) ERR-UNAUTHORIZED)
    (asserts! (> (len title) u0) ERR-INVALID-PARAMS)
    (asserts! (> (len description) u0) ERR-INVALID-PARAMS)
    (asserts! (> duration u0) ERR-INVALID-PARAMS)
    
    (let ((employer-id (unwrap-panic employer-id-opt)))
      (match (get-employer employer-id)
        employer-data 
        (begin
          (asserts! (get active employer-data) ERR-NOT-AVAILABLE)
          (map-set internships
            { internship-id: internship-id }
            {
              employer-id: employer-id,
              title: title,
              description: description,
              requirements: requirements,
              duration: duration,
              stipend: stipend,
              status: "open",
              created-at: current-block
            }
          )
          (var-set next-internship-id (+ internship-id u1))
          (ok internship-id)
        )
        ERR-NOT-FOUND
      )
    )
  )
)

(define-public (apply-for-internship (internship-id uint))
  (let
    (
      (applicant-id-opt (map-get? applicant-wallet-to-id tx-sender))
      (internship-opt (get-internship internship-id))
    )
    (asserts! (is-some applicant-id-opt) ERR-UNAUTHORIZED)
    (asserts! (is-some internship-opt) ERR-NOT-FOUND)
    
    (let 
      (
        (applicant-id (unwrap-panic applicant-id-opt))
        (internship-data (unwrap-panic internship-opt))
      )
      (match (get-applicant applicant-id)
        applicant-data
        (begin
          (asserts! (get available applicant-data) ERR-NOT-AVAILABLE)
          (asserts! (>= (get reputation applicant-data) u30) ERR-INSUFFICIENT-REPUTATION)
          (asserts! (is-eq (get status internship-data) "open") ERR-INVALID-STATUS)
          (ok true)
        )
        ERR-NOT-FOUND
      )
    )
  )
)

(define-public (create-match (applicant-id uint) (internship-id uint))
  (let
    (
      (match-id (var-get next-match-id))
      (employer-id-opt (map-get? employer-wallet-to-id tx-sender))
      (current-block burn-block-height)
    )
    (asserts! (is-some employer-id-opt) ERR-UNAUTHORIZED)
    
    (let 
      (
        (employer-id (unwrap-panic employer-id-opt))
        (applicant-opt (get-applicant applicant-id))
        (internship-opt (get-internship internship-id))
      )
      (asserts! (is-some applicant-opt) ERR-NOT-FOUND)
      (asserts! (is-some internship-opt) ERR-NOT-FOUND)
      
      (let 
        (
          (applicant-data (unwrap-panic applicant-opt))
          (internship-data (unwrap-panic internship-opt))
        )
        (asserts! (is-eq (get employer-id internship-data) employer-id) ERR-UNAUTHORIZED)
        (asserts! (get available applicant-data) ERR-NOT-AVAILABLE)
        (asserts! (is-eq (get status internship-data) "open") ERR-INVALID-STATUS)
        (asserts! (>= (get reputation applicant-data) u30) ERR-INSUFFICIENT-REPUTATION)
        
        (map-set matches
          { match-id: match-id }
          {
            applicant-id: applicant-id,
            employer-id: employer-id,
            internship-id: internship-id,
            status: "matched",
            created-at: current-block,
            completed-at: none,
            applicant-rating: none,
            employer-rating: none
          }
        )
        
        (map-set applicants
          { applicant-id: applicant-id }
          (merge (unwrap-panic applicant-opt) { available: false })
        )
        
        (map-set internships
          { internship-id: internship-id }
          (merge internship-data { status: "matched" })
        )
        
        (var-set next-match-id (+ match-id u1))
        (ok match-id)
      )
    )
  )
)

(define-public (start-internship (match-id uint))
  (let
    (
      (match-opt (get-match match-id))
      (current-block burn-block-height)
    )
    (asserts! (is-some match-opt) ERR-NOT-FOUND)
    
    (let ((match-data (unwrap-panic match-opt)))
      (let 
        (
          (employer-id-opt (map-get? employer-wallet-to-id tx-sender))
          (applicant-wallet-opt (match (get-applicant (get applicant-id match-data))
            applicant-data (some (get wallet applicant-data))
            none
          ))
        )
        (asserts! 
          (or 
            (and (is-some employer-id-opt) 
                 (is-eq (unwrap-panic employer-id-opt) (get employer-id match-data)))
            (and (is-some applicant-wallet-opt)
                 (is-eq (unwrap-panic applicant-wallet-opt) tx-sender))
          ) 
          ERR-UNAUTHORIZED
        )
        (asserts! (is-eq (get status match-data) "matched") ERR-INVALID-STATUS)
        
        (map-set matches
          { match-id: match-id }
          (merge match-data { status: "active" })
        )
        (ok true)
      )
    )
  )
)

(define-public (complete-internship (match-id uint))
  (let
    (
      (match-opt (get-match match-id))
      (current-block burn-block-height)
    )
    (asserts! (is-some match-opt) ERR-NOT-FOUND)
    
    (let ((match-data (unwrap-panic match-opt)))
      (let 
        (
          (employer-id-opt (map-get? employer-wallet-to-id tx-sender))
          (applicant-wallet-opt (match (get-applicant (get applicant-id match-data))
            applicant-data (some (get wallet applicant-data))
            none
          ))
        )
        (asserts! 
          (or 
            (and (is-some employer-id-opt) 
                 (is-eq (unwrap-panic employer-id-opt) (get employer-id match-data)))
            (and (is-some applicant-wallet-opt)
                 (is-eq (unwrap-panic applicant-wallet-opt) tx-sender))
          ) 
          ERR-UNAUTHORIZED
        )
        (asserts! (is-eq (get status match-data) "active") ERR-INVALID-STATUS)
        
        (map-set matches
          { match-id: match-id }
          (merge match-data { 
            status: "completed",
            completed-at: (some current-block)
          })
        )
        
        (let ((applicant-id (get applicant-id match-data)))
          (match (get-applicant applicant-id)
            applicant-data
            (map-set applicants
              { applicant-id: applicant-id }
              (merge applicant-data { available: true })
            )
            false
          )
        )
        
        (ok true)
      )
    )
  )
)

(define-public (rate-participant (match-id uint) (rating uint) (target (string-ascii 10)))
  (let
    (
      (match-opt (get-match match-id))
    )
    (asserts! (is-some match-opt) ERR-NOT-FOUND)
    (asserts! (and (>= rating u1) (<= rating u5)) ERR-INVALID-PARAMS)
    
    (let ((match-data (unwrap-panic match-opt)))
      (asserts! (is-eq (get status match-data) "completed") ERR-INVALID-STATUS)
      
      (let 
        (
          (employer-id-opt (map-get? employer-wallet-to-id tx-sender))
          (applicant-wallet-opt (match (get-applicant (get applicant-id match-data))
            applicant-data (some (get wallet applicant-data))
            none
          ))
          (is-employer (and (is-some employer-id-opt) 
                           (is-eq (unwrap-panic employer-id-opt) (get employer-id match-data))))
          (is-applicant (and (is-some applicant-wallet-opt)
                            (is-eq (unwrap-panic applicant-wallet-opt) tx-sender)))
        )
        (asserts! (or is-employer is-applicant) ERR-UNAUTHORIZED)
        
        (if (and is-employer (is-eq target "applicant"))
          (begin
            (map-set matches
              { match-id: match-id }
              (merge match-data { employer-rating: (some rating) })
            )
            (update-applicant-reputation (get applicant-id match-data) rating)
          )
          (if (and is-applicant (is-eq target "employer"))
            (begin
              (map-set matches
                { match-id: match-id }
                (merge match-data { applicant-rating: (some rating) })
              )
              (update-employer-reputation (get employer-id match-data) rating)
            )
            ERR-INVALID-PARAMS
          )
        )
      )
    )
  )
)

(define-private (update-applicant-reputation (applicant-id uint) (rating uint))
  (match (get-applicant applicant-id)
    applicant-data
    (let 
      (
        (current-rep (get reputation applicant-data))
        (new-rep (if (> rating u3)
          (+ current-rep u5)
          (if (< current-rep u5) u0 (- current-rep u5))
        ))
      )
      (map-set applicants
        { applicant-id: applicant-id }
        (merge applicant-data { reputation: new-rep })
      )
      (ok true)
    )
    ERR-NOT-FOUND
  )
)

(define-private (update-employer-reputation (employer-id uint) (rating uint))
  (match (get-employer employer-id)
    employer-data
    (let 
      (
        (current-rep (get reputation employer-data))
        (new-rep (if (> rating u3)
          (+ current-rep u5)
          (if (< current-rep u5) u0 (- current-rep u5))
        ))
      )
      (map-set employers
        { employer-id: employer-id }
        (merge employer-data { reputation: new-rep })
      )
      (ok true)
    )
    ERR-NOT-FOUND
  )
)

(define-public (set-availability (available bool))
  (let
    (
      (applicant-id-opt (map-get? applicant-wallet-to-id tx-sender))
    )
    (asserts! (is-some applicant-id-opt) ERR-UNAUTHORIZED)
    
    (let ((applicant-id (unwrap-panic applicant-id-opt)))
      (match (get-applicant applicant-id)
        applicant-data
        (begin
          (map-set applicants
            { applicant-id: applicant-id }
            (merge applicant-data { available: available })
          )
          (ok true)
        )
        ERR-NOT-FOUND
      )
    )
  )
)

(define-public (set-employer-status (active bool))
  (let
    (
      (employer-id-opt (map-get? employer-wallet-to-id tx-sender))
    )
    (asserts! (is-some employer-id-opt) ERR-UNAUTHORIZED)
    
    (let ((employer-id (unwrap-panic employer-id-opt)))
      (match (get-employer employer-id)
        employer-data
        (begin
          (map-set employers
            { employer-id: employer-id }
            (merge employer-data { active: active })
          )
          (ok true)
        )
        ERR-NOT-FOUND
      )
    )
  )
)
