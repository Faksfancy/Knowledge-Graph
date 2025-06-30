;; Knowledge Graph Network Smart Contract
;; This contract allows researchers to:
;; 1. Register research documents
;; 2. Record connections between documents
;; 3. Track citation metrics
;; 4. Verify document authenticity
;; 5. Implement knowledge contribution rewards

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_DUPLICATE_ENTRY (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_SELF_CITATION (err u103))
(define-constant ERR_INVALID_PARAMS (err u104))
(define-constant ERR_BAD_INPUT (err u105))

;; Data Structures

;; Research document information
(define-map documents
  { document-id: (string-ascii 64) }
  {
    title: (string-ascii 256),
    researcher: principal,
    timestamp: uint,
    category: (string-ascii 64),
    abstract: (string-utf8 1024),
    verified: bool
  }
)

;; Citation data
(define-map citation-records
  {
    citing-doc: (string-ascii 64),
    cited-doc: (string-ascii 64)
  }
  {
    timestamp: uint,
    context: (optional (string-utf8 256)),
    relevance: uint
  }
)

;; Citation count per document
(define-map citation-counts
  { document-id: (string-ascii 64) }
  { count: uint }
)

;; Researcher profile tracking
(define-map researcher-profiles
  { researcher: principal }
  {
    total-documents: uint,
    total-citations-received: uint,
    knowledge-score: uint
  }
)

;; Category-specific metrics
(define-map category-metrics
  { category: (string-ascii 64) }
  {
    total-documents: uint,
    total-citations: uint
  }
)

;; Contribution points for citations
(define-map knowledge-contributions
  { researcher: principal }
  { contribution-points: uint }
)

;; Approved verifiers
(define-map approved-verifiers
  { verifier: principal }
  { active: bool }
)

;; Validation functions

;; Validate string-ascii is not empty
(define-private (validate-string-ascii (input (string-ascii 256)))
  (> (len input) u0)
)

;; Validate string-utf8 is not empty (if present)
(define-private (validate-optional-string-utf8 (input (optional (string-utf8 256))))
  (match input
    some-val (> (len some-val) u0)
    true
  )
)

;; Validate document-id
(define-private (validate-document-id (document-id (string-ascii 64)))
  (and
    (> (len document-id) u0)
    (<= (len document-id) u64)
  )
)

;; Validate principal is not null
(define-private (validate-principal (user principal))
  (not (is-eq user 'SPNWZ5V2TPWGQGVDR6T7B6RQ4XMGZ4PXTEE0VQ0S))  ;; Check against zero/null address
)

;; Initialize functions

;; Initialize citation count for a document
(define-private (initialize-citation-count (document-id (string-ascii 64)))
  (map-set citation-counts
    { document-id: document-id }
    { count: u0 }
  )
)

;; Initialize researcher profile for a new researcher
(define-private (initialize-researcher-profile (researcher principal))
  (let ((researcher-data (map-get? researcher-profiles { researcher: researcher })))
    (if (is-some researcher-data)
      true
      (map-set researcher-profiles
        { researcher: researcher }
        {
          total-documents: u0,
          total-citations-received: u0,
          knowledge-score: u100
        }
      )
    )
  )
)

;; Initialize category metrics
(define-private (initialize-category-metrics (category (string-ascii 64)))
  (let ((category-data (map-get? category-metrics { category: category })))
    (if (is-some category-data)
      true
      (map-set category-metrics
        { category: category }
        {
          total-documents: u0,
          total-citations: u0
        }
      )
    )
  )
)

;; Initialize knowledge contributions
(define-private (initialize-knowledge-contributions (researcher principal))
  (let ((contribution-data (map-get? knowledge-contributions { researcher: researcher })))
    (if (is-some contribution-data)
      true
      (map-set knowledge-contributions
        { researcher: researcher }
        { contribution-points: u0 }
      )
    )
  )
)

;; Core Functions

;; Register a new research document
(define-public (register-document
                (document-id (string-ascii 64))
                (title (string-ascii 256))
                (category (string-ascii 64))
                (abstract (string-utf8 1024)))
  (let
    ((researcher tx-sender)
     (existing-document (map-get? documents { document-id: document-id })))
    (begin
      ;; Validate inputs
      (asserts! (validate-document-id document-id) ERR_BAD_INPUT)
      (asserts! (validate-string-ascii title) ERR_BAD_INPUT)
      (asserts! (validate-string-ascii category) ERR_BAD_INPUT)
      (asserts! (> (len abstract) u0) ERR_BAD_INPUT)
      
      (asserts! (is-none existing-document) ERR_DUPLICATE_ENTRY)
      
      ;; Initialize or update researcher profile
      (initialize-researcher-profile researcher)
      (map-set researcher-profiles
        { researcher: researcher }
        (merge
          (default-to
            { total-documents: u0, total-citations-received: u0, knowledge-score: u100 }
            (map-get? researcher-profiles { researcher: researcher })
          )
          { total-documents: (+ (get total-documents (default-to
                               { total-documents: u0, total-citations-received: u0, knowledge-score: u100 }
                               (map-get? researcher-profiles { researcher: researcher })))
                            u1) }
        )
      )
      
      ;; Initialize category metrics
      (initialize-category-metrics category)
      (map-set category-metrics
        { category: category }
        (merge
          (default-to
            { total-documents: u0, total-citations: u0 }
            (map-get? category-metrics { category: category })
          )
          { total-documents: (+ (get total-documents (default-to
                               { total-documents: u0, total-citations: u0 }
                               (map-get? category-metrics { category: category })))
                            u1) }
        )
      )
      
      ;; Create document record
      (map-set documents
        { document-id: document-id }
        {
          title: title,
          researcher: researcher,
          timestamp: block-height,
          category: category,
          abstract: abstract,
          verified: false
        }
      )
      
      ;; Initialize citation count
      (initialize-citation-count document-id)
      
      ;; Initialize knowledge contributions
      (initialize-knowledge-contributions researcher)
      
      (ok true)
    )
  )
)

;; Add a citation between two documents
(define-public (add-citation
               (citing-doc (string-ascii 64))
               (cited-doc (string-ascii 64))
               (context (optional (string-utf8 256)))
               (relevance uint))
  (let
    ((citing-doc-data (map-get? documents { document-id: citing-doc }))
     (cited-doc-data (map-get? documents { document-id: cited-doc })))
    (begin
      ;; Validate inputs
      (asserts! (validate-document-id citing-doc) ERR_BAD_INPUT)
      (asserts! (validate-document-id cited-doc) ERR_BAD_INPUT)
      (asserts! (validate-optional-string-utf8 context) ERR_BAD_INPUT)
      
      ;; Check if documents exist
      (asserts! (is-some citing-doc-data) ERR_NOT_FOUND)
      (asserts! (is-some cited-doc-data) ERR_NOT_FOUND)
      
      ;; Check if caller is the researcher of the citing document
      (asserts! (is-eq tx-sender (get researcher (unwrap! citing-doc-data ERR_NOT_FOUND))) ERR_UNAUTHORIZED)
      
      ;; Prevent self-citation (same document)
      (asserts! (not (is-eq citing-doc cited-doc)) ERR_SELF_CITATION)
      
      ;; Check valid relevance (1-10)
      (asserts! (and (>= relevance u1) (<= relevance u10)) ERR_INVALID_PARAMS)
      
      ;; Record the citation
      (map-set citation-records
        { citing-doc: citing-doc, cited-doc: cited-doc }
        {
          timestamp: block-height,
          context: context,
          relevance: relevance
        }
      )
      
      ;; Update citation count for cited document
      (map-set citation-counts
        { document-id: cited-doc }
        { count: (+ (get count (default-to { count: u0 } (map-get? citation-counts { document-id: cited-doc }))) u1) }
      )
      
      ;; Update total citations received for cited document's researcher
      (map-set researcher-profiles
        { researcher: (get researcher (unwrap! cited-doc-data ERR_NOT_FOUND)) }
        (merge
          (default-to
            { total-documents: u0, total-citations-received: u0, knowledge-score: u100 }
            (map-get? researcher-profiles { researcher: (get researcher (unwrap! cited-doc-data ERR_NOT_FOUND)) })
          )
          { 
            total-citations-received: (+ 
              (get total-citations-received
                (default-to
                  { total-documents: u0, total-citations-received: u0, knowledge-score: u100 }
                  (map-get? researcher-profiles { researcher: (get researcher (unwrap! cited-doc-data ERR_NOT_FOUND)) })
                )
              )
              u1
            ),
            knowledge-score: (+ 
              (get knowledge-score
                (default-to
                  { total-documents: u0, total-citations-received: u0, knowledge-score: u100 }
                  (map-get? researcher-profiles { researcher: (get researcher (unwrap! cited-doc-data ERR_NOT_FOUND)) })
                )
              )
              relevance
            )
          }
        )
      )
      
      ;; Update category metrics for cited document's category
      (map-set category-metrics
        { category: (get category (unwrap! cited-doc-data ERR_NOT_FOUND)) }
        (merge
          (default-to
            { total-documents: u0, total-citations: u0 }
            (map-get? category-metrics { category: (get category (unwrap! cited-doc-data ERR_NOT_FOUND)) })
          )
          { 
            total-citations: (+ 
              (get total-citations
                (default-to
                  { total-documents: u0, total-citations: u0 }
                  (map-get? category-metrics { category: (get category (unwrap! cited-doc-data ERR_NOT_FOUND)) })
                )
              )
              u1
            )
          }
        )
      )
      
      ;; Add contribution points to cited researcher
      (map-set knowledge-contributions
        { researcher: (get researcher (unwrap! cited-doc-data ERR_NOT_FOUND)) }
        { 
          contribution-points: (+ 
            (get contribution-points
              (default-to
                { contribution-points: u0 }
                (map-get? knowledge-contributions { researcher: (get researcher (unwrap! cited-doc-data ERR_NOT_FOUND)) })
              )
            )
            relevance
          )
        }
      )
      
      (ok true)
    )
  )
)

;; Verify document authenticity (can only be done by authorized verifiers)
(define-public (verify-document (document-id (string-ascii 64)))
  (let
    ((document-data (map-get? documents { document-id: document-id }))
     (verifier-data (map-get? approved-verifiers { verifier: tx-sender })))
    (begin
      ;; Validate document-id
      (asserts! (validate-document-id document-id) ERR_BAD_INPUT)
      
      (asserts! (is-some document-data) ERR_NOT_FOUND)
      (asserts! (is-some verifier-data) ERR_UNAUTHORIZED)
      (asserts! (get active (unwrap! verifier-data ERR_UNAUTHORIZED)) ERR_UNAUTHORIZED)
      
      (map-set documents
        { document-id: document-id }
        (merge (unwrap! document-data ERR_NOT_FOUND) { verified: true })
      )
      
      ;; Bonus score for verified documents
      (map-set researcher-profiles
        { researcher: (get researcher (unwrap! document-data ERR_NOT_FOUND)) }
        (merge
          (default-to
            { total-documents: u0, total-citations-received: u0, knowledge-score: u100 }
            (map-get? researcher-profiles { researcher: (get researcher (unwrap! document-data ERR_NOT_FOUND)) })
          )
          { 
            knowledge-score: (+ 
              (get knowledge-score
                (default-to
                  { total-documents: u0, total-citations-received: u0, knowledge-score: u100 }
                  (map-get? researcher-profiles { researcher: (get researcher (unwrap! document-data ERR_NOT_FOUND)) })
                )
              )
              u50
            )
          }
        )
      )
      
      (ok true)
    )
  )
)

;; Add a verifier (contract owner only)
(define-public (add-verifier (verifier principal))
  (begin
    ;; Validate verifier input
    (asserts! (validate-principal verifier) ERR_BAD_INPUT)
    
    ;; Validate verifier is not tx-sender (avoid self-authorization)
    (asserts! (not (is-eq verifier tx-sender)) ERR_BAD_INPUT)
    
    ;; Check authorization
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    
    ;; Check if already exists and active
    (let ((existing-verifier (map-get? approved-verifiers { verifier: verifier })))
      (asserts! (or (is-none existing-verifier) 
                    (not (get active (default-to { active: false } existing-verifier)))) 
                ERR_DUPLICATE_ENTRY)
    )
    
    ;; Add verifier
    (map-set approved-verifiers
      { verifier: verifier }
      { active: true }
    )
    (ok true)
  )
)

;; Remove a verifier (contract owner only)
(define-public (remove-verifier (verifier principal))
  (begin
    ;; Validate verifier input
    (asserts! (validate-principal verifier) ERR_BAD_INPUT)
    
    ;; Check authorization
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    
    ;; Validate verifier exists and is active
    (let ((existing-verifier (map-get? approved-verifiers { verifier: verifier })))
      (asserts! (is-some existing-verifier) ERR_NOT_FOUND)
      (asserts! (get active (default-to { active: false } existing-verifier)) ERR_NOT_FOUND)
    )
    
    ;; Deactivate verifier
    (map-set approved-verifiers
      { verifier: verifier }
      { active: false }
    )
    (ok true)
  )
)

;; Claim knowledge contribution rewards
(define-public (claim-contributions)
  (let
    ((researcher tx-sender)
     (rewards (default-to { contribution-points: u0 } (map-get? knowledge-contributions { researcher: researcher }))))
    (begin
      (asserts! (> (get contribution-points rewards) u0) ERR_INVALID_PARAMS)
      
      ;; Reset contribution points (In a real implementation, this would transfer tokens)
      (map-set knowledge-contributions
        { researcher: researcher }
        { contribution-points: u0 }
      )
      
      (ok (get contribution-points rewards))
    )
  )
)

;; Read-only functions

;; Get document details
(define-read-only (get-document-details (document-id (string-ascii 64)))
  (map-get? documents { document-id: document-id })
)

;; Get citation details
(define-read-only (get-citation-details (citing-doc (string-ascii 64)) (cited-doc (string-ascii 64)))
  (map-get? citation-records { citing-doc: citing-doc, cited-doc: cited-doc })
)

;; Get citation count for a document
(define-read-only (get-citation-count (document-id (string-ascii 64)))
  (default-to { count: u0 } (map-get? citation-counts { document-id: document-id }))
)

;; Get researcher profile
(define-read-only (get-researcher-profile (researcher principal))
  (default-to 
    { total-documents: u0, total-citations-received: u0, knowledge-score: u0 }
    (map-get? researcher-profiles { researcher: researcher })
  )
)

;; Get category metrics
(define-read-only (get-category-metrics (category (string-ascii 64)))
  (default-to
    { total-documents: u0, total-citations: u0 }
    (map-get? category-metrics { category: category })
  )
)

;; Get contribution points for a researcher
(define-read-only (get-contribution-points (researcher principal))
  (get contribution-points (default-to { contribution-points: u0 } (map-get? knowledge-contributions { researcher: researcher })))
)

;; Check if a user is a verifier
(define-read-only (is-verifier (verifier principal))
  (let
    ((verifier-data (map-get? approved-verifiers { verifier: verifier })))
    (if (is-some verifier-data)
      (get active (unwrap! verifier-data false))
      false
    )
  )
)

;; Get all citations for a document
(define-read-only (get-citations-for-document (document-id (string-ascii 64)) (as-cited bool))
  (if as-cited
    ;; Get all citations where this document is cited
    (get-citations-for-cited-document document-id u0)
    ;; Get all citations where this document cites others
    (get-citations-for-citing-document document-id u0)
  )
)

;; Helper functions for pagination (would need modification for real implementation)
(define-private (get-citations-for-cited-document (document-id (string-ascii 64)) (index uint))
  (ok "Citations would be returned here with pagination")
)

(define-private (get-citations-for-citing-document (document-id (string-ascii 64)) (index uint))
  (ok "Citations would be returned here with pagination")
)