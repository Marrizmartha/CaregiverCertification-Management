;; CaregiverCertification - Professional Caregiver Credential Management
;; Manages caregiver certifications and training records

(define-map caregivers
  { caregiver-id: uint }
  {
    caregiver-principal: principal,
    full-name: (string-ascii 100),
    certification-type: (string-ascii 50),
    issue-block: uint,
    expiry-block: uint,
    training-hours: uint,
    is-active: bool,
    issuer: principal
  }
)

(define-map training-records
  { record-id: uint }
  {
    caregiver-id: uint,
    course-name: (string-ascii 100),
    completion-block: uint,
    hours-completed: uint,
    instructor: (string-ascii 100),
    passed: bool
  }
)

(define-map certification-renewals
  { renewal-id: uint }
  {
    caregiver-id: uint,
    previous-expiry: uint,
    new-expiry: uint,
    renewed-at: uint,
    renewed-by: principal
  }
)

(define-data-var next-caregiver-id uint u1)
(define-data-var next-record-id uint u1)
(define-data-var next-renewal-id uint u1)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-input (err u102))
(define-constant err-already-certified (err u103))
(define-constant err-expired (err u104))
(define-constant err-not-active (err u105))

;; Issue new caregiver certification
(define-public (issue-certification
  (caregiver-principal principal)
  (full-name (string-ascii 100))
  (certification-type (string-ascii 50))
  (expiry-block uint)
  (training-hours uint)
)
  (let
    (
      (caregiver-id (var-get next-caregiver-id))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> expiry-block stacks-block-height) err-invalid-input)
    (asserts! (> (len full-name) u0) err-invalid-input)
    (asserts! (> training-hours u0) err-invalid-input)
    
    (map-set caregivers
      { caregiver-id: caregiver-id }
      {
        caregiver-principal: caregiver-principal,
        full-name: full-name,
        certification-type: certification-type,
        issue-block: stacks-block-height,
        expiry-block: expiry-block,
        training-hours: training-hours,
        is-active: true,
        issuer: tx-sender
      }
    )
    
    (var-set next-caregiver-id (+ caregiver-id u1))
    (ok caregiver-id)
  )
)

;; Add training record
(define-public (add-training-record
  (caregiver-id uint)
  (course-name (string-ascii 100))
  (hours-completed uint)
  (instructor (string-ascii 100))
  (passed bool)
)
  (let
    (
      (caregiver-data (unwrap! (map-get? caregivers { caregiver-id: caregiver-id }) err-not-found))
      (record-id (var-get next-record-id))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (get is-active caregiver-data) err-not-active)
    (asserts! (> (len course-name) u0) err-invalid-input)
    (asserts! (> hours-completed u0) err-invalid-input)
    
    (map-set training-records
      { record-id: record-id }
      {
        caregiver-id: caregiver-id,
        course-name: course-name,
        completion-block: stacks-block-height,
        hours-completed: hours-completed,
        instructor: instructor,
        passed: passed
      }
    )
    
    ;; Update total training hours
    (map-set caregivers
      { caregiver-id: caregiver-id }
      (merge caregiver-data { 
        training-hours: (+ (get training-hours caregiver-data) hours-completed) 
      })
    )
    
    (var-set next-record-id (+ record-id u1))
    (ok record-id)
  )
)

;; Renew certification
(define-public (renew-certification (caregiver-id uint) (new-expiry-block uint))
  (let
    (
      (caregiver-data (unwrap! (map-get? caregivers { caregiver-id: caregiver-id }) err-not-found))
      (renewal-id (var-get next-renewal-id))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (get is-active caregiver-data) err-not-active)
    (asserts! (> new-expiry-block stacks-block-height) err-invalid-input)
    
    (map-set certification-renewals
      { renewal-id: renewal-id }
      {
        caregiver-id: caregiver-id,
        previous-expiry: (get expiry-block caregiver-data),
        new-expiry: new-expiry-block,
        renewed-at: stacks-block-height,
        renewed-by: tx-sender
      }
    )
    
    (map-set caregivers
      { caregiver-id: caregiver-id }
      (merge caregiver-data { expiry-block: new-expiry-block })
    )
    
    (var-set next-renewal-id (+ renewal-id u1))
    (ok true)
  )
)

;; Revoke certification
(define-public (revoke-certification (caregiver-id uint))
  (let
    (
      (caregiver-data (unwrap! (map-get? caregivers { caregiver-id: caregiver-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set caregivers
      { caregiver-id: caregiver-id }
      (merge caregiver-data { is-active: false })
    )
    (ok true)
  )
)

;; Get caregiver information
(define-read-only (get-caregiver (caregiver-id uint))
  (map-get? caregivers { caregiver-id: caregiver-id })
)

;; Get training record
(define-read-only (get-training-record (record-id uint))
  (map-get? training-records { record-id: record-id })
)

;; Get renewal record
(define-read-only (get-renewal (renewal-id uint))
  (map-get? certification-renewals { renewal-id: renewal-id })
)

;; Check if certification is valid
(define-read-only (is-certification-valid (caregiver-id uint))
  (match (map-get? caregivers { caregiver-id: caregiver-id })
    caregiver-data
    (and 
      (get is-active caregiver-data)
      (> (get expiry-block caregiver-data) stacks-block-height)
    )
    false
  )
)

;; Get total training hours
(define-read-only (get-total-training-hours (caregiver-id uint))
  (match (map-get? caregivers { caregiver-id: caregiver-id })
    caregiver-data
    (ok (get training-hours caregiver-data))
    err-not-found
  )
)