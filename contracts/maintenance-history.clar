;; Maintenance History Contract
;; Tracks repairs and servicing for industrial equipment

;; Maintenance record structure
(define-map maintenance-records
  { record-id: uint }
  {
    asset-id: uint,
    date: uint,
    description: (string-utf8 256),
    technician: principal,
    cost: uint,
    parts-used: (list 20 uint)
  }
)

;; Asset to maintenance records mapping
(define-map asset-maintenance
  { asset-id: uint }
  { record-ids: (list 100 uint) }
)

;; Counter for maintenance record IDs
(define-data-var last-record-id uint u0)

;; Add a maintenance record
(define-public (add-maintenance-record
                (asset-id uint)
                (description (string-utf8 256))
                (cost uint)
                (parts-used (list 20 uint)))
  (let
    (
      (next-id (+ (var-get last-record-id) u1))
      (current-records (default-to { record-ids: (list) } (map-get? asset-maintenance { asset-id: asset-id })))
      (updated-records (merge current-records
                              { record-ids: (unwrap-panic
                                              (as-max-len? (append (get record-ids current-records) next-id) u100)) }))
    )
    (begin
      (var-set last-record-id next-id)
      (map-set maintenance-records
        { record-id: next-id }
        {
          asset-id: asset-id,
          date: block-height,
          description: description,
          technician: tx-sender,
          cost: cost,
          parts-used: parts-used
        }
      )
      (map-set asset-maintenance { asset-id: asset-id } updated-records)
      (ok next-id)
    )
  )
)

;; Get a maintenance record
(define-read-only (get-maintenance-record (record-id uint))
  (map-get? maintenance-records { record-id: record-id })
)

;; Get all maintenance records for an asset
(define-read-only (get-asset-maintenance-records (asset-id uint))
  (default-to { record-ids: (list) } (map-get? asset-maintenance { asset-id: asset-id }))
)

;; Get the latest maintenance record for an asset
(define-read-only (get-latest-maintenance (asset-id uint))
  (let
    (
      (records (get record-ids (default-to { record-ids: (list) } (map-get? asset-maintenance { asset-id: asset-id }))))
    )
    (if (> (len records) u0)
      (get-maintenance-record (unwrap-panic (element-at records (- (len records) u1))))
      none
    )
  )
)
