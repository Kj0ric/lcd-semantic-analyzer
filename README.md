<h1 align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/MIT_GNU_Scheme_Logo.svg/1200px-MIT_GNU_Scheme_Logo.svg.png" width="120" alt="MIT/GNU Scheme Logo"/>

  Semantic Analyzer for LCD Language in Scheme
</h1>

[![PL](https://img.shields.io/badge/MIT%2FGNU_Scheme-red?style=for-the-badge)](https://www.gnu.org/software/mit-scheme/)
![Status](https://img.shields.io/badge/status-completed-green?style=for-the-badge)
[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](https://github.com/Kj0ric/lcd-semantic-analyzer/blob/main/LICENSE)

## Table of Contents
- [Overview](#overview)
- [About the LCD Language](#about-the-lcd-language)
- [Grammar of the LCD Language](#grammar-of-the-lcd-language)
- [Implementation](#implementation)
- [Semantic Rules for LCD](#semantic-rules-for-lcd)
- [Example Run](#example-run)
- [Setup and Usage](#setup-and-usage)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Running the Project](#running-the-project)
- [Contributing](#contributing)
- [License](#license)

## Overview
This project implements a semantic analyzer for the LCD (Logic Circuit Design) language using MIT/GNU Scheme. It serves as a robust tool for validating LCD programs by enforcing semantic rules that ensure proper declaration and usage of circuit components. The analyzer is particularly useful in educational contexts for teaching programming language design and implementation, as well as in practical applications for verifying logic circuit descriptions.


## About the LCD Language
The LCD language facilitates logic circuit design through three main sections:

1. **Declarations**:
   - Introduces inputs, nodes, and outputs.
   - Example:
     ```
     input X, Y, Z
     node A, B, C
     output W, U
     ```

2. **Assignments**:
   - Defines the logical relationships between inputs, nodes, and outputs.
   - Example:
     ```
     A = X or Y
     B = A xor Y
     W = A and not Z
     ```

3. **Evaluation**:
   - Tests the designed circuits with different input combinations.
   - Example:
     ```
     evaluate circuit1 (X = true, Y = false, Z = true)
     ```

## Grammar of the LCD Language
The grammar of the LCD language can be described using Backus-Naur Form (BNF) notation as follows:

```bnf
<program> ::= <lcd>

<lcd> ::= 
          | <declarations> <circuitDesign> <evaluations>

<declarations> ::= <declaration> 
                 | <declaration> <declarations>

<declaration> ::= <input>
                | <output>
                | <node>

<input> ::= "input" <identifierList>

<output> ::= "output" <identifierList>

<node> ::= "node" <identifierList>

<identifierList> ::= <identifier>
                   | <identifier> "," <identifierList>

<circuitDesign> ::= <assignment>
                  | <assignment> <circuitDesign>

<assignment> ::= <identifier> "=" <expression>

<expression> ::= "not" <expression>
               | "(" <expression> ")"
               | <identifier>
               | <expression> "and" <expression>
               | <expression> "or" <expression>
               | <expression> "xor" <expression>
               | "true"
               | "false"

<evaluations> ::= <evaluation>
                | <evaluation> <evaluations>

<evaluation> ::= "evaluate" <identifier> "(" <evaluationAssignmentList> ")"

<evaluationAssignmentList> ::= <evaluationAssignment>
                             | <evaluationAssignment> "," <evaluationAssignmentList>

<evaluationAssignment> ::= <identifier> "=" "true"
                         | <identifier> "=" "false"
```

## Implementation
The semantic analyzer is implemented as a collection of Scheme functions. It processes LCD programs represented as nested lists, structured as follows:
```scheme
(define lcd-program
  '(
    ;; Declarations
    (("input" X Y Z)
     ("node" A B C)
     ("output" W U))

    ;; Assignments
    ((A = X or Y)
     (B = A xor Y)
     (W = A and not Z))

    ;; Evaluation
    (("evaluate" circuit1 ((X true) (Y false) (Z true))))
  ))
```

## Semantic Rules for LCD

Each function of the semantic analyzer is responsible from enforcing specific rules to ensure the correctness of LCD programs:

### 1. find-undeclared identifiers
```scheme
(define find-undeclared-identifiers
  (lambda (lcd) ... ))
```
Rules implemented:
- Rule 1. **Undeclared Identifiers**: All identifiers used in the **Assignments** or **Evaluation** blocks must be declared in the **Declarations** block.

### 2. find-multiple-declarations
```scheme
(define find-undeclared-identifiers
  (lambda (lcd) ... ))
```
Rules implemented:
- Rule 2. **Undeclared Identifiers**: An identifier can be declared only once, even if the declarations are of different types (e.g., input, node, output).

### 3. check-identifier-usage
```scheme
(define check-identifier-usage
  (lambda (lcd) ... ))
```
Rules implemented:
- Rule 3.  **Unused Inputs**: Every input declared in the **Declarations** block must be used in the **Assignments** section.
- Rule 4. **Unassigned Nodes and Outputs**: Every identifier that is defined in the **Declarations** block as a node or an output must appear on the left-hand side of an assignment in the **Assignments** block.
- Rule 5. **Multiple Assignments to Nodes and Outputs**: An identifier that is defined in the **Declarations** block as a node or as an output cannot be assigned multiple times.

### 4. check-inputs-in-evaluation
```scheme
(define check-inputs-in-evaluation
  (lambda (lcd) ... ))
```
Rules implemented:
- Rule 6. **Unassigned Inputs in Evaluation**: Every input identifier has to be assigned a value in each circuit evaluation statement.
- Rule 7. **Multiple Assignments to Inputs in Evaluation**: An input cannot be assigned multiple times in an evaluation.

### 5. check-incorrect-assignments
```scheme
(define check-incorrect-assignments
  (lambda (lcd) ... ))
```
Rules implemented:
- Rule 8. **Incorrect Assignments to Inputs**: An input can only be assigned in the **Evaluation** block.
- Rule 9. **Incorrect Assignments to Nodes and Outputs**: A node or an output can only be assigned in the **Evaluation** block.

---

## Example Run 
An LCD program including violations for each rule:
```scheme
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
```

Outputs:
```scheme
1 ]=> (find-undeclared-identifiers example-program)

;Value: (input4 node4 undeclared_input)

1 ]=> (find-multiple-declarations example-program)

;Value: (input2 node1)

1 ]=> (check-identifier-usage example-program)

;Value: ((input3) () (output2 node2))

1 ]=> (check-inputs-in-evaluation example-program)

;Value: ((circuit1 circuit2 circuit3 circuit4) (circuit1))

1 ]=> (check-incorrect-assignments example-program)

;Value: ((input2) (node1 output1))
```

## Setup and Usage

### Prerequisites
- MIT/GNU Scheme (version 11.2 or higher)
- Basic understanding of Scheme/Lisp programming
- Git (optional, for cloning the repository)

### Installation
#### 1. Install MIT/GNU Scheme
- Linux (Debian/Ubuntu)
```bash
sudo apt-get update
sudo apt-get install mit-scheme
```
- macOS (using Homebrew)
```bash
brew install mit-scheme
```
- Windows
  - Download the installer from MIT/GNU Scheme website
  - Run the installer and follow the installation wizard
  - Add MIT/GNU Scheme to your system's PATH

#### 2. Get the Project
- Either clone the repository:
```bash
git clone https://github.com/yourusername/lcd-semantic-analyzer.git
cd lcd-semantic-analyzer
```
- Or download the source files directly.

### Running the Project

1. Start MIT/GNU Scheme
  ```bash
  scheme
  ```

2. Load the semantic analyzer
  ```scheme
  (load "semantic-analyzer.scm")
  ```

3. Define an LCD program for testing
  ```scheme
  (define test-program
    '(
      (("input" X Y)
       ("node" A)
       ("output" Z))
      ((A = X and Y)
       (Z = A or X))
      (("evaluate" test1 ((X true) (Y false))))
    ))
  ```

4. Run the semantic analysis functions
  ```scheme
  (find-undeclared-identifiers test-program)
  (find-multiple-declarations test-program)
  (check-identifier-usage test-program)
  (check-inputs-in-evaluation test-program)
  (check-incorrect-assignments test-program)
  ```
## Contributing
Contributions are welcome! If you'd like to contribute:

1. Fork the repository
2. Create a new branch (git checkout -b feature/improvement)
3. Make your changes
4. Commit your changes (git commit -am 'Add new feature')
5. Push to the branch (git push origin feature/improvement)
6. Create a Pull Request

## License 
This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments
- This project was developed as part of my Programming Languages course
- Thanks to the MIT/GNU Scheme development team for their excellent Scheme implementation
