;; Community Mental Health Outreach Contract
;; Manages mobile crisis teams and community intervention programs

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INVALID-INPUT (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-UNAVAILABLE (err u103))
(define-constant ERR-OPERATION-FAILED (err u104))

;; Data Variables
(define-data-var next-team-id uint u1)
(define-data-var next-intervention-id uint u1)
(define-data-var next-program-id uint u1)

;; Data Maps
(define-map mobile-crisis-teams
  { team-id: uint }
  {
    team-name: (string-ascii 100),
    lead-coordinator: principal,
    team-members: (string-ascii 300), ;; comma-separated member info
    specializations: (string-ascii 200),
    coverage-area: (string-ascii 100),
    vehicle-info: (string-ascii 100),
    equipment-list: (string-ascii 300),
    status: uint, ;; 1=available, 2=deployed, 3=off-duty, 4=maintenance
    current-location: (string-ascii 100),
    response-time-avg: uint, ;; in blocks
    total-interventions: uint,
    success-rate: uint,
    created-at: uint
  }
)

(define-map crisis-interventions
  { intervention-id: uint }
  {
    team-id: uint,
    location: (string-ascii 200),
    incident-type: (string-ascii 100), ;; suicide-risk, psychotic-episode, etc.
    priority-level: uint, ;; 1=low, 2=medium, 3=high, 4=emergency
    reported-by: principal,
    dispatch-time: uint,
    arrival-time: (optional uint),
    completion-time: (optional uint),
    outcome: (string-ascii 300),
    follow-up-required: bool,
    resources-used: (string-ascii 200),
    status: uint, ;; 1=dispatched, 2=en-route, 3=on-scene, 4=completed, 5=cancelled
    notes: (string-ascii 500)
  }
)

(define-map outreach-programs
  { program-id: uint }
  {
    program-name: (string-ascii 100),
    description: (string-ascii 300),
    coordinator: principal,
    target-population: (string-ascii 100),
    service-area: (string-ascii 100),
    program-type: (string-ascii 50), ;; education, screening, support, etc.
    schedule: (string-ascii 200),
    capacity: uint,
    current-participants: uint,
    volunteer-count: uint,
    professional-staff: uint,
    budget-allocated: uint,
    budget-used: uint,
    status: uint, ;; 1=active, 2=planning, 3=on-hold, 0=inactive
    start-date: uint,
    end-date: (optional uint)
  }
)

(define-map staff-assignments
  { staff-principal: principal, assignment-date: uint }
  {
    team-id: (optional uint),
    program-id: (optional uint),
    role: (string-ascii 50), ;; coordinator, counselor, volunteer, etc.
    certification-level: uint,
    hours-committed: uint,
    assignment-type: uint, ;; 1=permanent, 2=temporary, 3=volunteer
    status: uint ;; 1=active, 2=inactive, 3=on-leave
  }
)

(define-map community-metrics
  { area: (string-ascii 100), date: uint }
  {
    population-served: uint,
    interventions-completed: uint,
    programs-active: uint,
    volunteer-hours: uint,
    professional-hours: uint,
    resources-distributed: uint,
    satisfaction-rating: uint,
    follow-up-rate: uint
  }
)

;; Create mobile crisis team
(define-public (create-crisis-team
  (team-name (string-ascii 100))
  (team-members (string-ascii 300))
  (specializations (string-ascii 200))
  (coverage-area (string-ascii 100))
  (vehicle-info (string-ascii 100))
  (equipment-list (string-ascii 300)))

  (let ((team-id (var-get next-team-id)))
    (asserts! (> (len team-name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len coverage-area) u0) ERR-INVALID-INPUT)

    (map-set mobile-crisis-teams
      { team-id: team-id }
      {
        team-name: team-name,
        lead-coordinator: tx-sender,
        team-members: team-members,
        specializations: specializations,
        coverage-area: coverage-area,
        vehicle-info: vehicle-info,
        equipment-list: equipment-list,
        status: u1,
        current-location: "base",
        response-time-avg: u0,
        total-interventions: u0,
        success-rate: u100,
        created-at: block-height
      }
    )

    (var-set next-team-id (+ team-id u1))
    (ok team-id)
  )
)

;; Dispatch crisis intervention
(define-public (dispatch-intervention
  (team-id uint)
  (location (string-ascii 200))
  (incident-type (string-ascii 100))
  (priority-level uint))

  (let ((team (unwrap! (map-get? mobile-crisis-teams { team-id: team-id }) ERR-NOT-FOUND))
        (intervention-id (var-get next-intervention-id)))

    (asserts! (>= priority-level u1) ERR-INVALID-INPUT)
    (asserts! (<= priority-level u4) ERR-INVALID-INPUT)
    (asserts! (is-eq (get status team) u1) ERR-UNAVAILABLE)
    (asserts! (> (len location) u0) ERR-INVALID-INPUT)

    (map-set crisis-interventions
      { intervention-id: intervention-id }
      {
        team-id: team-id,
        location: location,
        incident-type: incident-type,
        priority-level: priority-level,
        reported-by: tx-sender,
        dispatch-time: block-height,
        arrival-time: none,
        completion-time: none,
        outcome: "",
        follow-up-required: false,
        resources-used: "",
        status: u1,
        notes: ""
      }
    )

    ;; Update team status to deployed
    (map-set mobile-crisis-teams
      { team-id: team-id }
      (merge team { status: u2 })
    )

    (var-set next-intervention-id (+ intervention-id u1))
    (ok intervention-id)
  )
)

;; Update intervention status
(define-public (update-intervention-status
  (intervention-id uint)
  (new-status uint)
  (notes (string-ascii 500)))

  (let ((intervention (unwrap! (map-get? crisis-interventions { intervention-id: intervention-id }) ERR-NOT-FOUND))
        (team (unwrap! (map-get? mobile-crisis-teams { team-id: (get team-id intervention) }) ERR-NOT-FOUND)))

    (asserts! (is-eq tx-sender (get lead-coordinator team)) ERR-UNAUTHORIZED)
    (asserts! (>= new-status u1) ERR-INVALID-INPUT)
    (asserts! (<= new-status u5) ERR-INVALID-INPUT)

    (let ((updated-intervention (merge intervention {
      status: new-status,
      notes: notes,
      arrival-time: (if (and (is-eq new-status u3) (is-none (get arrival-time intervention)))
                     (some block-height)
                     (get arrival-time intervention)),
      completion-time: (if (or (is-eq new-status u4) (is-eq new-status u5))
                        (some block-height)
                        (get completion-time intervention))
    })))

      (map-set crisis-interventions
        { intervention-id: intervention-id }
        updated-intervention
      )

      ;; Update team status if intervention completed
      (if (or (is-eq new-status u4) (is-eq new-status u5))
        (begin
          (map-set mobile-crisis-teams
            { team-id: (get team-id intervention) }
            (merge team {
              status: u1,
              total-interventions: (+ (get total-interventions team) u1)
            })
          )
          true
        )
        true
      )

      (ok true)
    )
  )
)

;; Create outreach program
(define-public (create-outreach-program
  (program-name (string-ascii 100))
  (description (string-ascii 300))
  (target-population (string-ascii 100))
  (service-area (string-ascii 100))
  (program-type (string-ascii 50))
  (schedule (string-ascii 200))
  (capacity uint)
  (budget-allocated uint))

  (let ((program-id (var-get next-program-id)))
    (asserts! (> (len program-name) u0) ERR-INVALID-INPUT)
    (asserts! (> capacity u0) ERR-INVALID-INPUT)
    (asserts! (< capacity u1000) ERR-INVALID-INPUT)

    (map-set outreach-programs
      { program-id: program-id }
      {
        program-name: program-name,
        description: description,
        coordinator: tx-sender,
        target-population: target-population,
        service-area: service-area,
        program-type: program-type,
        schedule: schedule,
        capacity: capacity,
        current-participants: u0,
        volunteer-count: u0,
        professional-staff: u1, ;; coordinator counts as staff
        budget-allocated: budget-allocated,
        budget-used: u0,
        status: u2, ;; planning phase
        start-date: block-height,
        end-date: none
      }
    )

    (var-set next-program-id (+ program-id u1))
    (ok program-id)
  )
)

;; Assign staff to team or program
(define-public (assign-staff
  (team-id (optional uint))
  (program-id (optional uint))
  (role (string-ascii 50))
  (certification-level uint)
  (hours-committed uint)
  (assignment-type uint))

  (begin
    (asserts! (or (is-some team-id) (is-some program-id)) ERR-INVALID-INPUT)
    (asserts! (>= certification-level u1) ERR-INVALID-INPUT)
    (asserts! (<= certification-level u5) ERR-INVALID-INPUT)
    (asserts! (> hours-committed u0) ERR-INVALID-INPUT)
    (asserts! (>= assignment-type u1) ERR-INVALID-INPUT)
    (asserts! (<= assignment-type u3) ERR-INVALID-INPUT)

    ;; Validate team or program exists
    (if (is-some team-id)
      (asserts! (is-some (map-get? mobile-crisis-teams { team-id: (unwrap-panic team-id) })) ERR-NOT-FOUND)
      true
    )

    (if (is-some program-id)
      (asserts! (is-some (map-get? outreach-programs { program-id: (unwrap-panic program-id) })) ERR-NOT-FOUND)
      true
    )

    (map-set staff-assignments
      { staff-principal: tx-sender, assignment-date: block-height }
      {
        team-id: team-id,
        program-id: program-id,
        role: role,
        certification-level: certification-level,
        hours-committed: hours-committed,
        assignment-type: assignment-type,
        status: u1
      }
    )

    (ok true)
  )
)

;; Update team location
(define-public (update-team-location (team-id uint) (new-location (string-ascii 100)))
  (let ((team (unwrap! (map-get? mobile-crisis-teams { team-id: team-id }) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get lead-coordinator team)) ERR-UNAUTHORIZED)
    (asserts! (> (len new-location) u0) ERR-INVALID-INPUT)

    (map-set mobile-crisis-teams
      { team-id: team-id }
      (merge team { current-location: new-location })
    )
    (ok true)
  )
)

;; Record community metrics
(define-public (record-community-metrics
  (area (string-ascii 100))
  (population-served uint)
  (interventions-completed uint)
  (programs-active uint)
  (volunteer-hours uint)
  (professional-hours uint)
  (resources-distributed uint)
  (satisfaction-rating uint))

  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (> (len area) u0) ERR-INVALID-INPUT)
    (asserts! (<= satisfaction-rating u5) ERR-INVALID-INPUT)

    (map-set community-metrics
      { area: area, date: block-height }
      {
        population-served: population-served,
        interventions-completed: interventions-completed,
        programs-active: programs-active,
        volunteer-hours: volunteer-hours,
        professional-hours: professional-hours,
        resources-distributed: resources-distributed,
        satisfaction-rating: satisfaction-rating,
        follow-up-rate: u0 ;; to be updated separately
      }
    )
    (ok true)
  )
)

;; Activate outreach program
(define-public (activate-program (program-id uint))
  (let ((program (unwrap! (map-get? outreach-programs { program-id: program-id }) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get coordinator program)) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get status program) u2) ERR-INVALID-INPUT) ;; must be in planning

    (map-set outreach-programs
      { program-id: program-id }
      (merge program { status: u1 })
    )
    (ok true)
  )
)

;; Get crisis team info
(define-read-only (get-crisis-team (team-id uint))
  (map-get? mobile-crisis-teams { team-id: team-id })
)

;; Get intervention info
(define-read-only (get-intervention (intervention-id uint))
  (map-get? crisis-interventions { intervention-id: intervention-id })
)

;; Get outreach program info
(define-read-only (get-outreach-program (program-id uint))
  (map-get? outreach-programs { program-id: program-id })
)

;; Get staff assignment
(define-read-only (get-staff-assignment (staff-principal principal) (assignment-date uint))
  (map-get? staff-assignments { staff-principal: staff-principal, assignment-date: assignment-date })
)

;; Get community metrics
(define-read-only (get-community-metrics (area (string-ascii 100)) (date uint))
  (map-get? community-metrics { area: area, date: date })
)

;; Get system overview
(define-read-only (get-system-overview)
  {
    total-teams: (- (var-get next-team-id) u1),
    total-interventions: (- (var-get next-intervention-id) u1),
    total-programs: (- (var-get next-program-id) u1)
  }
)
