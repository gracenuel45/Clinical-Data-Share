;; Automated Clinical Data Sharing Smart Contract
;; This contract enables secure, permissioned sharing of anonymized clinical data
;; with comprehensive access control, data integrity, and audit trails

;; Error constants for validation and authorization
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-INVALID-DATA-ID (err u101))
(define-constant ERR-DATA-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-PERMISSION (err u103))
(define-constant ERR-INVALID-RESEARCHER (err u104))
(define-constant ERR-ACCESS-EXPIRED (err u105))
(define-constant ERR-INSUFFICIENT-PERMISSIONS (err u106))
(define-constant ERR-INVALID-STUDY-ID (err u107))
(define-constant ERR-DATA-NOT-FOUND (err u108))
(define-constant ERR-INVALID-INSTITUTION (err u109))
(define-constant ERR-CONSENT-REVOKED (err u110))
(define-constant ERR-INVALID-TIMESTAMP (err u111))
(define-constant ERR-HASH-MISMATCH (err u112))

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MAX-DATA-SIZE u1000000)
(define-constant MIN-ACCESS-DURATION u86400) ;; 24 hours in seconds
(define-constant MAX-ACCESS-DURATION u31536000) ;; 1 year in seconds

;; Data variables for contract state
(define-data-var next-data-id uint u1)
(define-data-var next-study-id uint u1)
(define-data-var contract-paused bool false)
(define-data-var total-data-records uint u0)
(define-data-var total-access-requests uint u0)

;; Define clinical data structure with anonymization metadata
(define-map clinical-data
  { data-id: uint }
  {
    data-hash: (buff 32),
    anonymization-level: uint,
    data-type: (string-ascii 50),
    study-category: (string-ascii 100),
    upload-timestamp: uint,
    data-provider: principal,
    consent-status: bool,
    access-count: uint,
    data-size: uint,
    metadata: (string-ascii 500)
  }
)

;; Define research studies and their requirements
(define-map research-studies
  { study-id: uint }
  {
    study-name: (string-ascii 200),
    principal-investigator: principal,
    institution: (string-ascii 100),
    study-purpose: (string-ascii 500),
    required-data-types: (list 10 (string-ascii 50)),
    ethics-approval: (string-ascii 100),
    start-date: uint,
    end-date: uint,
    participant-count: uint,
    status: (string-ascii 20)
  }
)

;; Access permissions mapping
(define-map data-access-permissions
  { data-id: uint, researcher: principal }
  {
    permission-level: uint,
    granted-timestamp: uint,
    expiry-timestamp: uint,
    study-id: uint,
    access-purpose: (string-ascii 200),
    granted-by: principal,
    usage-restrictions: (string-ascii 300),
    is-active: bool
  }
)

;; Researcher credentials and verification
(define-map verified-researchers
  { researcher: principal }
  {
    institution: (string-ascii 100),
    credentials: (string-ascii 200),
    verification-date: uint,
    research-areas: (list 5 (string-ascii 50)),
    ethics-clearance: bool,
    reputation-score: uint,
    is-verified: bool
  }
)

;; Data access logs for audit trails
(define-map access-logs
  { log-id: uint }
  {
    data-id: uint,
    researcher: principal,
    access-timestamp: uint,
    access-type: (string-ascii 30),
    ip-hash: (buff 32),
    study-id: uint,
    duration: uint
  }
)

;; Consent management for data subjects
(define-map consent-records
  { consent-id: (buff 32) }
  {
    consent-timestamp: uint,
    consent-scope: (string-ascii 200),
    data-types-consented: (list 10 (string-ascii 50)),
    withdrawal-allowed: bool,
    expiry-date: uint,
    consent-version: uint,
    is-active: bool
  }
)

;; Institution verification and trust scores
(define-map verified-institutions
  { institution-id: (string-ascii 100) }
  {
    institution-name: (string-ascii 200),
    verification-authority: (string-ascii 100),
    trust-score: uint,
    certification-date: uint,
    contact-info: (string-ascii 300),
    compliance-status: bool,
    is-verified: bool
  }
)

;; Data usage statistics and analytics
(define-map usage-statistics
  { data-id: uint }
  {
    total-accesses: uint,
    unique-researchers: uint,
    last-access-date: uint,
    download-count: uint,
    citation-count: uint,
    impact-score: uint
  }
)

;; Upload anonymized clinical data with comprehensive metadata
(define-public (upload-clinical-data
    (data-hash (buff 32))
    (anonymization-level uint)
    (data-type (string-ascii 50))
    (study-category (string-ascii 100))
    (data-size uint)
    (metadata (string-ascii 500))
    (consent-id (buff 32)))
  (let
    (
      (current-data-id (var-get next-data-id))
      (current-timestamp (unwrap! (get-block-info? time (- block-height u1)) ERR-INVALID-TIMESTAMP))
    )
    ;; Validate input parameters
    (asserts! (not (var-get contract-paused)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> data-size u0) ERR-INVALID-DATA-ID)
    (asserts! (<= data-size MAX-DATA-SIZE) ERR-INVALID-DATA-ID)
    (asserts! (>= anonymization-level u1) ERR-INVALID-DATA-ID)
    (asserts! (<= anonymization-level u5) ERR-INVALID-DATA-ID)
    
    ;; Verify consent exists and is active
    (asserts! 
      (match (map-get? consent-records { consent-id: consent-id })
        consent-data (get is-active consent-data)
        false) 
      ERR-CONSENT-REVOKED)
    
    ;; Store clinical data record
    (map-set clinical-data
      { data-id: current-data-id }
      {
        data-hash: data-hash,
        anonymization-level: anonymization-level,
        data-type: data-type,
        study-category: study-category,
        upload-timestamp: current-timestamp,
        data-provider: tx-sender,
        consent-status: true,
        access-count: u0,
        data-size: data-size,
        metadata: metadata
      }
    )
    
    ;; Initialize usage statistics
    (map-set usage-statistics
      { data-id: current-data-id }
      {
        total-accesses: u0,
        unique-researchers: u0,
        last-access-date: u0,
        download-count: u0,
        citation-count: u0,
        impact-score: u0
      }
    )
    
    ;; Update contract state
    (var-set next-data-id (+ current-data-id u1))
    (var-set total-data-records (+ (var-get total-data-records) u1))
    
    (ok current-data-id)
  )
)

;; Register a new research study with detailed information
(define-public (register-study
    (study-name (string-ascii 200))
    (institution (string-ascii 100))
    (study-purpose (string-ascii 500))
    (required-data-types (list 10 (string-ascii 50)))
    (ethics-approval (string-ascii 100))
    (end-date uint)
    (participant-count uint))
  (let
    (
      (current-study-id (var-get next-study-id))
      (current-timestamp (unwrap! (get-block-info? time (- block-height u1)) ERR-INVALID-TIMESTAMP))
    )
    ;; Validate researcher is verified
    (asserts! (is-verified-researcher tx-sender) ERR-INVALID-RESEARCHER)
    
    ;; Validate institution is verified
    (asserts! 
      (match (map-get? verified-institutions { institution-id: institution })
        inst-data (get is-verified inst-data)
        false)
      ERR-INVALID-INSTITUTION)
    
    ;; Validate study parameters
    (asserts! (> (len study-name) u0) ERR-INVALID-STUDY-ID)
    (asserts! (> end-date current-timestamp) ERR-INVALID-TIMESTAMP)
    (asserts! (> participant-count u0) ERR-INVALID-STUDY-ID)
    
    ;; Register the study
    (map-set research-studies
      { study-id: current-study-id }
      {
        study-name: study-name,
        principal-investigator: tx-sender,
        institution: institution,
        study-purpose: study-purpose,
        required-data-types: required-data-types,
        ethics-approval: ethics-approval,
        start-date: current-timestamp,
        end-date: end-date,
        participant-count: participant-count,
        status: "active"
      }
    )
    
    (var-set next-study-id (+ current-study-id u1))
    (ok current-study-id)
  )
)

;; Request access to specific clinical data for research purposes
(define-public (request-data-access
    (data-id uint)
    (study-id uint)
    (access-duration uint)
    (access-purpose (string-ascii 200))
    (usage-restrictions (string-ascii 300)))
  (let
    (
      (current-timestamp (unwrap! (get-block-info? time (- block-height u1)) ERR-INVALID-TIMESTAMP))
      (expiry-timestamp (+ current-timestamp access-duration))
    )
    ;; Validate inputs
    (asserts! (is-some (map-get? clinical-data { data-id: data-id })) ERR-DATA-NOT-FOUND)
    (asserts! (is-some (map-get? research-studies { study-id: study-id })) ERR-INVALID-STUDY-ID)
    (asserts! (is-verified-researcher tx-sender) ERR-INVALID-RESEARCHER)
    (asserts! (>= access-duration MIN-ACCESS-DURATION) ERR-INVALID-PERMISSION)
    (asserts! (<= access-duration MAX-ACCESS-DURATION) ERR-INVALID-PERMISSION)
    
    ;; Verify study is active and researcher is the PI
    (let ((study-data (unwrap! (map-get? research-studies { study-id: study-id }) ERR-INVALID-STUDY-ID)))
      (asserts! (is-eq (get principal-investigator study-data) tx-sender) ERR-UNAUTHORIZED-ACCESS)
      (asserts! (is-eq (get status study-data) "active") ERR-INVALID-STUDY-ID)
    )
    
    ;; Grant access permission (auto-approval for now, could add manual review)
    (map-set data-access-permissions
      { data-id: data-id, researcher: tx-sender }
      {
        permission-level: u1,
        granted-timestamp: current-timestamp,
        expiry-timestamp: expiry-timestamp,
        study-id: study-id,
        access-purpose: access-purpose,
        granted-by: CONTRACT-OWNER,
        usage-restrictions: usage-restrictions,
        is-active: true
      }
    )
    
    (var-set total-access-requests (+ (var-get total-access-requests) u1))
    (ok true)
  )
)

;; Access clinical data with proper authorization and logging
(define-public (access-clinical-data
    (data-id uint)
    (access-type (string-ascii 30))
    (ip-hash (buff 32)))
  (let
    (
      (current-timestamp (unwrap! (get-block-info? time (- block-height u1)) ERR-INVALID-TIMESTAMP))
      (permission-data (unwrap! (map-get? data-access-permissions { data-id: data-id, researcher: tx-sender }) ERR-UNAUTHORIZED-ACCESS))
      (clinical-record (unwrap! (map-get? clinical-data { data-id: data-id }) ERR-DATA-NOT-FOUND))
    )
    ;; Validate access permission
    (asserts! (get is-active permission-data) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (< current-timestamp (get expiry-timestamp permission-data)) ERR-ACCESS-EXPIRED)
    
    ;; Verify consent is still active
    (asserts! (get consent-status clinical-record) ERR-CONSENT-REVOKED)
    
    ;; Log the access
    (let ((log-id (+ (var-get total-access-requests) u1)))
      (map-set access-logs
        { log-id: log-id }
        {
          data-id: data-id,
          researcher: tx-sender,
          access-timestamp: current-timestamp,
          access-type: access-type,
          ip-hash: ip-hash,
          study-id: (get study-id permission-data),
          duration: u0
        }
      )
    )
    
    ;; Update access count and usage statistics
    (map-set clinical-data
      { data-id: data-id }
      (merge clinical-record { access-count: (+ (get access-count clinical-record) u1) })
    )
    
    ;; Update usage statistics
    (let ((usage-stats (default-to 
          { total-accesses: u0, unique-researchers: u0, last-access-date: u0, 
            download-count: u0, citation-count: u0, impact-score: u0 }
          (map-get? usage-statistics { data-id: data-id }))))
      (map-set usage-statistics
        { data-id: data-id }
        (merge usage-stats 
          { 
            total-accesses: (+ (get total-accesses usage-stats) u1),
            last-access-date: current-timestamp,
            download-count: (if (is-eq access-type "download") 
                             (+ (get download-count usage-stats) u1) 
                             (get download-count usage-stats))
          }
        )
      )
    )
    
    (ok (get data-hash clinical-record))
  )
)

;; Verify and register a researcher with credentials
(define-public (verify-researcher
    (researcher principal)
    (institution (string-ascii 100))
    (credentials (string-ascii 200))
    (research-areas (list 5 (string-ascii 50)))
    (ethics-clearance bool))
  (let
    (
      (current-timestamp (unwrap! (get-block-info? time (- block-height u1)) ERR-INVALID-TIMESTAMP))
    )
    ;; Only contract owner can verify researchers (could be extended to authorized verifiers)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED-ACCESS)
    
    ;; Validate institution is verified
    (asserts! 
      (match (map-get? verified-institutions { institution-id: institution })
        inst-data (get is-verified inst-data)
        false)
      ERR-INVALID-INSTITUTION)
    
    (map-set verified-researchers
      { researcher: researcher }
      {
        institution: institution,
        credentials: credentials,
        verification-date: current-timestamp,
        research-areas: research-areas,
        ethics-clearance: ethics-clearance,
        reputation-score: u100,
        is-verified: true
      }
    )
    
    (ok true)
  )
)

;; Register and verify an institution
(define-public (register-institution
    (institution-id (string-ascii 100))
    (institution-name (string-ascii 200))
    (verification-authority (string-ascii 100))
    (contact-info (string-ascii 300))
    (compliance-status bool))
  (let
    (
      (current-timestamp (unwrap! (get-block-info? time (- block-height u1)) ERR-INVALID-TIMESTAMP))
    )
    ;; Only contract owner can register institutions
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED-ACCESS)
    
    (map-set verified-institutions
      { institution-id: institution-id }
      {
        institution-name: institution-name,
        verification-authority: verification-authority,
        trust-score: u100,
        certification-date: current-timestamp,
        contact-info: contact-info,
        compliance-status: compliance-status,
        is-verified: true
      }
    )
    
    (ok true)
  )
)

;; Record consent for data sharing
(define-public (record-consent
    (consent-id (buff 32))
    (consent-scope (string-ascii 200))
    (data-types-consented (list 10 (string-ascii 50)))
    (withdrawal-allowed bool)
    (expiry-date uint)
    (consent-version uint))
  (let
    (
      (current-timestamp (unwrap! (get-block-info? time (- block-height u1)) ERR-INVALID-TIMESTAMP))
    )
    ;; Validate consent parameters
    (asserts! (> expiry-date current-timestamp) ERR-INVALID-TIMESTAMP)
    (asserts! (> consent-version u0) ERR-INVALID-PERMISSION)
    
    (map-set consent-records
      { consent-id: consent-id }
      {
        consent-timestamp: current-timestamp,
        consent-scope: consent-scope,
        data-types-consented: data-types-consented,
        withdrawal-allowed: withdrawal-allowed,
        expiry-date: expiry-date,
        consent-version: consent-version,
        is-active: true
      }
    )
    
    (ok true)
  )
)

;; Withdraw consent for data sharing
(define-public (withdraw-consent (consent-id (buff 32)))
  (let
    (
      (consent-data (unwrap! (map-get? consent-records { consent-id: consent-id }) ERR-CONSENT-REVOKED))
    )
    ;; Check if withdrawal is allowed
    (asserts! (get withdrawal-allowed consent-data) ERR-INSUFFICIENT-PERMISSIONS)
    
    ;; Deactivate consent
    (map-set consent-records
      { consent-id: consent-id }
      (merge consent-data { is-active: false })
    )
    
    (ok true)
  )
)

;; Revoke data access permissions
(define-public (revoke-access
    (data-id uint)
    (researcher principal))
  (let
    (
      (clinical-record (unwrap! (map-get? clinical-data { data-id: data-id }) ERR-DATA-NOT-FOUND))
      (permission-data (unwrap! (map-get? data-access-permissions { data-id: data-id, researcher: researcher }) ERR-UNAUTHORIZED-ACCESS))
    )
    ;; Only data provider or contract owner can revoke access
    (asserts! (or (is-eq tx-sender (get data-provider clinical-record))
                  (is-eq tx-sender CONTRACT-OWNER)) 
              ERR-UNAUTHORIZED-ACCESS)
    
    ;; Deactivate permission
    (map-set data-access-permissions
      { data-id: data-id, researcher: researcher }
      (merge permission-data { is-active: false })
    )
    
    (ok true)
  )
)

;; Update citation count for impact tracking
(define-public (update-citation-count
    (data-id uint)
    (citation-increment uint))
  (let
    (
      (usage-stats (default-to 
        { total-accesses: u0, unique-researchers: u0, last-access-date: u0, 
          download-count: u0, citation-count: u0, impact-score: u0 }
        (map-get? usage-statistics { data-id: data-id })))
    )
    ;; Verify data exists and researcher has access
    (asserts! (is-some (map-get? clinical-data { data-id: data-id })) ERR-DATA-NOT-FOUND)
    (asserts! (has-active-access data-id tx-sender) ERR-UNAUTHORIZED-ACCESS)
    
    ;; Update citation count and recalculate impact score
    (let ((new-citations (+ (get citation-count usage-stats) citation-increment)))
      (map-set usage-statistics
        { data-id: data-id }
        (merge usage-stats 
          { 
            citation-count: new-citations,
            impact-score: (calculate-impact-score new-citations (get total-accesses usage-stats))
          }
        )
      )
    )
    
    (ok true)
  )
)

;; Emergency pause contract (admin only)
(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED-ACCESS)
    (var-set contract-paused true)
    (ok true)
  )
)

;; Resume contract operations (admin only)
(define-public (resume-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED-ACCESS)
    (var-set contract-paused false)
    (ok true)
  )
)

;; Read-only function to check if researcher is verified
(define-read-only (is-verified-researcher (researcher principal))
  (match (map-get? verified-researchers { researcher: researcher })
    researcher-data (get is-verified researcher-data)
    false
  )
)

;; Read-only function to check active access permissions
(define-read-only (has-active-access (data-id uint) (researcher principal))
  (let
    (
      (current-timestamp (default-to u0 (get-block-info? time (- block-height u1))))
    )
    (match (map-get? data-access-permissions { data-id: data-id, researcher: researcher })
      permission-data (and (get is-active permission-data)
                          (< current-timestamp (get expiry-timestamp permission-data)))
      false
    )
  )
)

;; Read-only function to get clinical data information (excluding sensitive data)
(define-read-only (get-data-info (data-id uint))
  (map-get? clinical-data { data-id: data-id })
)

;; Read-only function to get study information
(define-read-only (get-study-info (study-id uint))
  (map-get? research-studies { study-id: study-id })
)

;; Read-only function to get usage statistics
(define-read-only (get-usage-stats (data-id uint))
  (map-get? usage-statistics { data-id: data-id })
)

;; Read-only function to get researcher information
(define-read-only (get-researcher-info (researcher principal))
  (map-get? verified-researchers { researcher: researcher })
)

;; Read-only function to get institution information
(define-read-only (get-institution-info (institution-id (string-ascii 100)))
  (map-get? verified-institutions { institution-id: institution-id })
)

;; Read-only function to check consent status
(define-read-only (get-consent-status (consent-id (buff 32)))
  (map-get? consent-records { consent-id: consent-id })
)

;; Read-only function to get contract statistics
(define-read-only (get-contract-stats)
  {
    total-data-records: (var-get total-data-records),
    total-access-requests: (var-get total-access-requests),
    next-data-id: (var-get next-data-id),
    next-study-id: (var-get next-study-id),
    contract-paused: (var-get contract-paused)
  }
)

;; Helper function to calculate impact score
(define-read-only (calculate-impact-score (citations uint) (accesses uint))
  (let
    (
      (base-score (+ (* citations u10) accesses))
      (popularity-factor (if (> accesses u100) u2 u1))
    )
    (* base-score popularity-factor)
  )
)

;; Read-only function to verify data integrity
(define-read-only (verify-data-integrity (data-id uint) (provided-hash (buff 32)))
  (match (map-get? clinical-data { data-id: data-id })
    data-record (is-eq (get data-hash data-record) provided-hash)
    false
  )
)