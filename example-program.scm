(define example-program
  '(
    ;; Declarations - Rules 2 (Multiple declarations)
    (("input" input1 input2)
     ("node" node1 node2)
     ("output" output1 output2)
     ("input" input2)           ; Multiple declaration of input2
     ("node" node1)            ; Multiple declaration of node1
     ("input" input3))         ; Will be unused (Rule 3)

    ;; Assignments - Rules 1,3,4,5,8
    ((node1 = input1 or (not input4))    ; input4 undeclared (Rule 1)
     (node2 = node1 and input2)
     (output1 = input1 and node2)
     (output2 = node4 or node2)          ; node4 undeclared (Rule 1)
     (output2 = node1 or node2)          ; Multiple assignment to output2 (Rule 5)
     (input2 = node1 and input1)         ; Incorrect assignment to input (Rule 8)
     (node2 = input1 or input2))         ; Multiple assignment to node2 (Rule 5)
     ; node3 is never assigned (Rule 4)

    ;; Evaluation - Rules 6,7,9
    (("evaluate" circuit1 ((input1 true) (input2 true) (input2 false)))    ; Multiple assignment to input2 (Rule 7)
     ("evaluate" circuit2 ((node1 true) (output1 false)))                  ; Incorrect assignment to node/output (Rule 9)
     ("evaluate" circuit3 ((input1 true)))                                 ; Missing input2 assignment (Rule 6)
     ("evaluate" circuit4 ((input2 false) (undeclared_input true))))      ; Using undeclared identifier (Rule 1)
  ))