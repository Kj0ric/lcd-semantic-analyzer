; ---------------------------------------------------------------------------
; Helper functions related to identifiers  
; ---------------------------------------------------------------------------

; Helper function to check if a symbol is an operator
(define is-operator?
  (lambda (symbl)
    (member symbl '(and or not xor))))

; Helper function to check if identifier was seen before
(define seen-before?
  (lambda (identifier seen-list)
    (member identifier seen-list)))

; ---------------------------------------------------------------------------
; Helper functions to extract identifiers from declarations block 
; ---------------------------------------------------------------------------

; Helper function to extract all declared identifiers from declarations block
(define get-declared-identifiers
  (lambda (declarations)
    ; Flatten the declarations list and remove the type indicators ("input", "node", "output")
    (let loop ((decl declarations)
               (rslt '()))
      (cond
        ; If declarations list is empty, return result
        ((null? decl) rslt)
        ; Process each declaration sublist
        (else
          (let ((cur-decl (car decl)))
            ; Skip the first element (type indicator) and add rest to result
            (loop (cdr decl)
                  (append rslt (cdr cur-decl)))))))))

; Helper function to get all input identifiers
(define get-inputs-declared
  (lambda (declarations)
    (let loop ((decls declarations)
               (inputs '()))
      (if (null? decls)
          inputs
          (let ((cur-decl (car decls)))
            (if (equal? (car cur-decl) "input")
                (loop (cdr decls) (append inputs (cdr cur-decl)))
                (loop (cdr decls) inputs)))))))

; Helper function to get all node and output identifiers
(define get-nodes-and-outputs-declared
  (lambda (declarations)
    (let loop ((decls declarations)
               (identifiers '()))
      (if (null? decls)
          identifiers
          (let ((cur-decl (car decls)))
            (if (or (equal? (car cur-decl) "node")
                    (equal? (car cur-decl) "output"))
                (loop (cdr decls) (append identifiers (cdr cur-decl)))
                (loop (cdr decls) identifiers)))))))

; ---------------------------------------------------------------------------
; Helper functions to process declarations-related identifiers
; ---------------------------------------------------------------------------

; Helper function to get identifiers from a single declaration
(define get-identifiers-from-declaration
  (lambda (declaration)
    (cdr declaration)))

; Helper function to process a single declaration
; Returns three values: new duplicates found in this declaration,
; updated seen list, and the order matters here
(define process-single-declaration
  (lambda (declaration seen-list)
    (let loop ((ids (get-identifiers-from-declaration declaration))
               (cur-seen seen-list)
               (cur-duplicates '()))
      (if (null? ids)
          ; Return results in correct order
          (cons (reverse cur-duplicates) cur-seen)
          (let ((cur-id (car ids)))
            (if (seen-before? cur-id cur-seen)
                ; If seen before, add to duplicates
                (loop (cdr ids)
                      cur-seen
                      (cons cur-id cur-duplicates))
                ; If new, just add to seen list
                (loop (cdr ids)
                      (cons cur-id cur-seen)
                      cur-duplicates)))))))

; ---------------------------------------------------------------------------
; Helper functions to extract identifiers from expressions/assignments
; --------------------------------------------------------------------------- 

; Helper function to extract identifiers from a SINGLE expression
(define get-expression-identifiers
  (lambda (expr)
    (cond
      ; If expression is empty, return empty list
      ((null? expr) '())
      ; If expression is a symbol (identifier) and not an operator, return it in a list
      ((and (symbol? expr) (not (is-operator? expr))) 
       (list expr))
      ; If expression is not a list (e.g., boolean), return empty list
      ((not (list? expr)) '())
      ; If expression is a list, process each element recursively
      (else
        (let loop ((remaining expr)
                   (result '()))
          (if (null? remaining)
              result
              (append result
                      (get-expression-identifiers (car remaining))
                      (loop (cdr remaining) '()))))))))

; Helper function to extract identifiers from ALL assignments in the assignment block 
(define get-assignment-identifiers
  (lambda (assignments)
    (let loop ((assign assignments)
               (result '()))
      (cond
        ((null? assign) result)
        (else
          ; For each assignment (node1 = input3 or (not input4))
          ; Get identifiers from both sides of the assignment
          (let* ((cur-assign (car assign))
                 ; Get left side identifier (before =)
                 (left-side (car cur-assign))
                 ; Get right side expression (after =)
                 (right-side (cddr cur-assign))
                 ; Get identifiers from right side expression
                 (right-identifiers (get-expression-identifiers right-side)))
            (loop (cdr assign)
                  (append result 
                         (list left-side)
                         right-identifiers))))))))

; Helper function to get identifiers used in expressions (right side of assignments)
(define get-used-identifiers
  (lambda (assignments)
    (let loop ((assigns assignments)
               (used '()))
      (if (null? assigns)
          used
          (let* ((cur-assign (car assigns))
                 (right-side (cddr cur-assign))
                 (right-identifiers (get-expression-identifiers right-side)))
            (loop (cdr assigns)
                  (append used right-identifiers)))))))

; Helper function to get assigned identifiers (left side of assignments)
(define get-assigned-identifiers
  (lambda (assignments)
    (map car assignments)))


; ---------------------------------------------------------------------------
; Helper functions to process assignments-related identifiers
; --------------------------------------------------------------------------- 

; Helper function to find unused inputs (Rule 3)
(define find-unused-inputs
  (lambda (declarations assignments)
    (let* ((inputs (get-inputs-declared declarations))
           (used (get-used-identifiers assignments)))
      (filter (lambda (input)
                (not (member input used)))
              inputs))))

; Helper function to find unassigned nodes and outputs (Rule 4)
(define find-unassigned-nodes-and-outputs
  (lambda (declarations assignments)
    (let* ((nodes-and-outputs (get-nodes-and-outputs-declared declarations))
           (assigned (get-assigned-identifiers assignments)))
      (filter (lambda (id)
                (not (member id assigned)))
              nodes-and-outputs))))

; Helper function to find multiple assigned identifiers (Rule 5)
(define find-multiple-assignments
  (lambda (assignments)
    (let loop ((ids (get-assigned-identifiers assignments))
               (seen '())
               (duplicates-order '()))
      (if (null? ids)
          duplicates-order
          (let ((cur-id (car ids)))
            (if (and (member cur-id seen)
                    (not (member cur-id duplicates-order)))
                (loop (cdr ids) 
                      seen 
                      (append duplicates-order (list cur-id)))
                (loop (cdr ids) 
                      (cons cur-id seen) 
                      duplicates-order)))))))

; ---------------------------------------------------------------------------
; Helper functions to extract identifiers from evaluations block
; --------------------------------------------------------------------------- 

; Helper function to extract identifiers from evaluations block
(define get-evaluation-identifiers
  (lambda (evaluations)
    (let loop ((eval evaluations)
               (result '()))
      (cond
        ((null? eval) result)
        (else
          ; For each evaluation ("evaluate" circuit1 ((input1 true) (input2 true)))
          ; Get identifiers from the assignments
          (let* ((cur-eval (car eval))
                 ; Get the assignments part ((input1 true) (input2 true))
                 (eval-assignments (caddr cur-eval))
                 ; Extract just the identifiers (input1, input2)
                 (identifiers (map car eval-assignments)))
            (loop (cdr eval)
                  (append result identifiers))))))))

; Helper function to get assigned inputs in a single evaluation
(define get-evaluation-inputs
  (lambda (evaluation)
    (map car (caddr evaluation))))

; Helper function to get assigned identifiers from evaluations
(define get-evaluation-assignments
  (lambda (evaluations)
    (let loop ((evals evaluations)
               (assigned '()))
      (if (null? evals)
          assigned
          (let ((eval-assignments (map car (caddr (car evals)))))
            (loop (cdr evals)
                  (append assigned eval-assignments)))))))

; ---------------------------------------------------------------------------
; Helper functions to process evaluations-related identifiers
; --------------------------------------------------------------------------- 

; Helper function to check if all required inputs are assigned in an evaluation
(define check-missing-inputs
  (lambda (all-inputs evaluation)
    (let loop ((inputs all-inputs)
               (eval-inputs (get-evaluation-inputs evaluation)))
      (cond
        ((null? inputs) #f)  ; No missing inputs
        ((not (member (car inputs) eval-inputs)) #t)  ; Found a missing input
        (else (loop (cdr inputs) eval-inputs))))))

; Helper function to check for duplicate inputs in a single evaluation
(define has-duplicate-inputs?
  (lambda (evaluation)
    (let loop ((inputs (get-evaluation-inputs evaluation))
               (seen '()))
      (cond
        ((null? inputs) #f)
        ((member (car inputs) seen) #t)
        (else (loop (cdr inputs) (cons (car inputs) seen)))))))

; Helper function to process evaluations for both rules
(define process-evaluations
  (lambda (all-inputs evaluations)
    (let loop ((evals evaluations)
               (missing-inputs '())
               (duplicate-inputs '()))
      (if (null? evals)
          (list missing-inputs duplicate-inputs)
          (let* ((cur-eval (car evals))
                 (eval-name (cadr cur-eval))
                 ; Check for missing inputs
                 (has-missing (check-missing-inputs all-inputs cur-eval))
                 ; Check for duplicate inputs
                 (has-duplicates (has-duplicate-inputs? cur-eval))
                 ; Update lists based on checks
                 (new-missing (if has-missing
                                (append missing-inputs (list eval-name))
                                missing-inputs))
                 (new-duplicates (if has-duplicates
                                    (append duplicate-inputs (list eval-name))
                                    duplicate-inputs)))
            (loop (cdr evals)
                  new-missing
                  new-duplicates))))))

; Helper function to find incorrectly assigned inputs in circuit design
(define find-incorrect-inputs
  (lambda (declarations assignments)
    (let ((inputs (get-inputs-declared declarations))
          (assigned (get-assigned-identifiers assignments)))
      (filter (lambda (id)
                (member id inputs))
              assigned))))

; Helper function to find incorrectly assigned nodes and outputs in evaluations
(define find-incorrect-nodes-outputs
  (lambda (declarations evaluations)
    (let ((nodes-and-outputs (get-nodes-and-outputs-declared declarations))
          (eval-assignments (get-evaluation-assignments evaluations)))
      (filter (lambda (id)
                (member id nodes-and-outputs))
              eval-assignments))))

; ---------------------------------------------------------------------------
; Main Functions that implement RULES 1-9
; ---------------------------------------------------------------------------

; Main function to find undeclared identifiers (Rule 1)
(define find-undeclared-identifiers
  (lambda (lcd)
    (let* ((declarations (car lcd))     ; Get declarations (first element)
           (assignments (cadr lcd))     ; Get assignments (second element)
           (evaluations (caddr lcd))    ; Get evaluations (third element)
           ; Get all declared identifiers
           (declared (get-declared-identifiers declarations))
           ; Get all used identifiers from assignments and evaluations
           (used-in-assignments (get-assignment-identifiers assignments))
           (used-in-evaluations (get-evaluation-identifiers evaluations))
           ; Combine all used identifiers
           (all-used (append used-in-assignments used-in-evaluations)))
      ; Filter out identifiers that are used but not declared
      (filter (lambda (id) 
                (not (member id declared)))
              all-used))))

; Main function to find multiple declarations (Rule 2)
(define find-multiple-declarations
  (lambda (lcd)
    (let loop ((declarations (car lcd))
               (seen-list '())
               (result '()))
      (if (null? declarations)
          result  ; Final result is already in correct order
          (let* ((processed (process-single-declaration 
                             (car declarations) 
                             seen-list))
                 (new-duplicates (car processed))
                 (new-seen (cdr processed)))
            (loop (cdr declarations)
                  new-seen
                  ; Append new duplicates to maintain order
                  (append result new-duplicates)))))))

; Main function to check identifier usage (Rules 3-5)
(define check-identifier-usage
  (lambda (lcd)
    (let* ((declarations (car lcd))
           (assignments (cadr lcd))
           ; Find unused inputs (Rule 3)
           (unused-inputs (find-unused-inputs declarations assignments))
           ; Find unassigned nodes and outputs (Rule 4)
           (unassigned-nodes-outputs (find-unassigned-nodes-and-outputs declarations assignments))
           ; Find multiple assigned identifiers (Rule 5)
           (multiple-assignments (find-multiple-assignments assignments)))
      (list unused-inputs unassigned-nodes-outputs multiple-assignments))))

; Main function to check inputs in evaluation (Rules 6-7)
(define check-inputs-in-evaluation
  (lambda (lcd)
    (let* ((declarations (car lcd))
           (evaluations (caddr lcd))
           (all-inputs (get-inputs-declared declarations)))
      (process-evaluations all-inputs evaluations))))

; Main function to check incorrect assignments (Rules 8-9)
(define check-incorrect-assignments
  (lambda (lcd)
    (let* ((declarations (car lcd))
           (assignments (cadr lcd))
           (evaluations (caddr lcd))
           ; Find inputs assigned in circuit design (Rule 8)
           (incorrect-inputs (find-incorrect-inputs declarations assignments))
           ; Find nodes/outputs assigned in evaluations (Rule 9)
           (incorrect-nodes-outputs (find-incorrect-nodes-outputs declarations evaluations)))
      (list incorrect-inputs incorrect-nodes-outputs))))
