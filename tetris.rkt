;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname tetris) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
;                                            
;                                            
;  ;;;;;;; ;;;;; ;;;;;;; ;;;;;  ;;;;;   ;;;; 
;     ;    ;        ;    ;    ;   ;    ;;   ;
;     ;    ;        ;    ;    ;   ;    ;     
;     ;    ;        ;    ;    ;   ;    ;;    
;     ;    ;;;;;    ;    ;;;;;    ;     ;;;; 
;     ;    ;        ;    ;   ;    ;         ;
;     ;    ;        ;    ;    ;   ;         ;
;     ;    ;        ;    ;    ;   ;    ;    ;
;     ;    ;;;;;    ;    ;     ;;;;;;   ;;;; 
;                                            
;                                            
;                                            

;----------------------------------------------------------------------------------------------------
; Tetris 
;----------------------------------------------------------------------------------------------------
(require 2htdp/image)
(require 2htdp/universe)

;----------------------------------------------------------------------------------------------------
; Constants
;----------------------------------------------------------------------------------------------------
(define GRID-SQSIZE 20) ; the width and height of the grid squares
(define BOARD-HEIGHT 20) ; the height of the game board in grid squares
(define BOARD-WIDTH 10) ; the width of the game board in grid squares
(define BOARD-HEIGHT/PIX (* BOARD-HEIGHT GRID-SQSIZE)) ; board height in pixels
(define BOARD-WIDTH/PIX (* BOARD-WIDTH GRID-SQSIZE)) ; board width in pixels

(define BACKGROUND (empty-scene BOARD-WIDTH/PIX BOARD-HEIGHT/PIX))

(define TICK-RATE 0.3)

;----------------------------------------------------------------------------------------------------
; Data Definitions
;----------------------------------------------------------------------------------------------------

;                                                                                                  
;                                                                                                  
;   ;;;;    ;   ;;;;;   ;         ;;;;  ;;;;  ;;;;  ;;;;;;;  ;  ;;;;; ;;;;; ;;;;;  ;;; ;;  ;   ;;; 
;   ;  ;;   ;     ;     ;         ;  ;; ;     ;       ;  ;;  ;    ;     ;     ;   ;   ;;;  ;  ;   ;
;   ;   ;  ; ;    ;    ; ;        ;   ; ;;;;  ;;;;    ;  ;;  ;    ;     ;     ;   ;   ;;;  ;  ;    
;   ;   ;  ; ;    ;    ; ;        ;   ; ;     ;       ;  ; ; ;    ;     ;     ;   ;   ;; ; ;   ;;; 
;   ;   ;  ;;;    ;    ;;;        ;   ; ;     ;       ;  ; ; ;    ;     ;     ;   ;   ;; ; ;      ;
;   ;  ;; ;   ;   ;   ;   ;       ;  ;; ;     ;       ;  ;  ;;    ;     ;     ;   ;   ;;  ;;  ;   ;
;   ;;;;  ;   ;   ;   ;   ;       ;;;;  ;;;;  ;     ;;;;;;  ;;  ;;;;;   ;   ;;;;;  ;;; ;  ;;   ;;; 
;                                                                                                  
;                                                                                                  
;                                                                                                  

(define-struct world [piece lob score])
; a World is a (make-world Piece LOB Natural)
; where piece is a piece in Tetris
; lob is a list of bricks that make up the pile of pieces at the bottom of the board
; and score is the player's current score.
; Interpretation: represents the state of the world.

(define-struct piece [lob center])
; a Piece is a (make-piece NElob Posn)
; lob is a non empty list of bricks that make up the piece
; center is the grid coordinates of the center of the piece
; Interp: represents a piece in Tetris.

(define-struct brick [x y color])
; A Brick is a (make-brick Integer Integer Color)
; Interpretation: A (make-brick x-g y-g c) represents a square brick 
; at position (x-g, y-g) in the grid, to be rendered in color c.

; a NElob (Non-Empty ListOfBricks) is one of:
; (cons Brick Empty)
; (cons Brick LOB)
; Interpretation: a non-empty list of bricks, represents a tetris piece.

; an LOB (ListOfBricks) is one of:
; '()
; (cons Brick LOB)
; Interpretation: a list of bricks, represents a pile of bricks at the bottom of the tetris board.

; a TypeNumber is a Natural from [0, 8]
; Interp: represents a type of tetris piece with a number.

; a Rows is a Natural from [0, 19]
; Interp: represents a number of rows.

; a Probability is a Natural from [0, 100]
; Interp: represents a probability.

;----------------------------------------------------------------------------------------------------
; Examples & Templates
;----------------------------------------------------------------------------------------------------
; EXAMPLES:

;                                                          
;                                                          
;   ;;;;;  ;    ;   ;;  ;;  ;;  ;;;;;  ;      ;;;;;   ;;;; 
;   ;       ;  ;    ;;  ;;  ;;  ;    ; ;      ;      ;;   ;
;   ;       ;;;;    ;;  ;;  ;;  ;    ; ;      ;      ;     
;   ;        ;;    ;  ; ; ;; ;  ;   ;; ;      ;      ;;    
;   ;;;;;    ;;    ;  ; ; ;; ;  ;;;;;  ;      ;;;;;   ;;;; 
;   ;        ;;    ;  ; ;    ;  ;      ;      ;           ;
;   ;       ;  ;   ;;;; ;    ;  ;      ;      ;           ;
;   ;       ;  ;  ;    ;;    ;  ;      ;      ;      ;    ;
;   ;;;;;  ;    ; ;    ;;    ;  ;      ;;;;;; ;;;;;   ;;;; 
;                                                          
;                                                          
;                                                          

(define center1 (make-posn 5 3))
(define brick1 (make-brick 4 3 "blue"))
(define brick2 (make-brick 5 3 "blue")) ; center brick
(define brick3 (make-brick 6 3 "blue"))
(define brick4 (make-brick 7 3 "blue"))
(define lob1 (list brick1 brick2 brick3 brick4))
(define i-piece-example (make-piece lob1 center1)) ; example of an "I" tetra
(define world1 (make-world i-piece-example '() 0))

(define center2 (make-posn 2 10))
(define brick5 (make-brick 2 10 "green")) ; center brick
(define brick6 (make-brick 2 11 "green"))
(define brick7 (make-brick 3 10 "green"))
(define brick8 (make-brick 3 11 "green"))
(define lob2 (list brick5 brick6 brick7 brick8))
(define o-piece-example (make-piece lob2 center2)) ; example of an "O" tetra
(define world2 (make-world o-piece-example '() 0))

(define center-below (make-posn -5 -3))
(define brick-below1 (make-brick -4 -3 "blue"))
(define brick-below2 (make-brick -5 -3 "blue")) ; center brick
(define brick-below3 (make-brick -6 -3 "blue"))
(define brick-below4 (make-brick -7 -3 "blue"))
(define lob-below (list brick-below1 brick-below2 brick-below3 brick-below4))
(define piece-below (make-piece lob-below center-below)) ; example of a tetra below the board
(define world-below (make-world piece-below '() 0))

(define center-right (make-posn 9 8))
(define brick-right1 (make-brick 8 9 "red"))
(define brick-right2 (make-brick 8 8 "red"))
(define brick-right3 (make-brick 9 8 "red")) ; center brick
(define brick-right4 (make-brick 9 7 "red"))
(define lob-right (list brick-right1 brick-right2 brick-right3 brick-right4))
(define piece-right (make-piece lob-right center-right)) ; touching right edge of board
(define world-right (make-world piece-right '() 0))

(define center-left (make-posn 0 9))
(define brick-left1 (make-brick 1 10 "cyan"))
(define brick-left2 (make-brick 0 10 "cyan"))
(define brick-left3 (make-brick 0 9 "cyan")) ; center brick
(define brick-left4 (make-brick 0 8 "cyan"))
(define lob-left (list brick-left1 brick-left2 brick-left3 brick-left4))
(define piece-left (make-piece lob-left center-left)) ; touching left edge of board
(define world-left (make-world piece-left '() 0))

(define center-above (make-posn 9 80))
(define brick-above1 (make-brick 8 90 "red"))
(define brick-above2 (make-brick 8 80 "red"))
(define brick-above3 (make-brick 9 80 "red")) ; center brick
(define brick-above4 (make-brick 9 70 "red"))
(define lob-above (list brick-above1 brick-above2 brick-above3 brick-above4))
(define piece-above (make-piece lob-above center-above)) ; above the board
(define world-above (make-world piece-above '() 0))

(define pile1 '()) ; examples of piles of bricks at the bottom of board
(define pile2 (list (make-brick 0 0 "grey") (make-brick 1 0 "grey")))
(define pile3 (make-brick 0 0 "grey"))
(define pile4 (list
               (make-brick 2 2 "orange")
               (make-brick 2 1 "orange")
               (make-brick 3 1 "orange")
               (make-brick 2 0 "orange")
               (make-brick 3 0 "red")
               (make-brick 4 0 "red")
               (make-brick 4 1 "red")
               (make-brick 5 1 "red")
               (make-brick 0 0 "green")
               (make-brick 1 0 "green")
               (make-brick 0 1 "green")
               (make-brick 1 1 "green")
               (make-brick 5 0 "dark green")
               (make-brick 6 0 "dark green")
               (make-brick 7 0 "dark green")
               (make-brick 8 0 "dark green")
               (make-brick 9 0 "dark green")))

(define tn-o 0) ; examples of TypeNumber
(define tn-i 1)
(define tn-l 2)

(define rows-ex1 0) ; examples of Rows
(define rows-ex2 19)
(define rows-ex3 2)

(define prob-ex1 0) ; examples of Probability
(define prob-ex2 100)
(define prob-ex3 33)

(define world-full (make-world o-piece-example pile4 0)) ; example of a world w/ a full row

; examples of [List-of LOB]
(define lolob1 (list '() '() '() '() '() '() '() '() '() '() '() '() '() '() '() '() '() '() '() '()))
(define lolob2
  (list
   (list
    (make-brick 2 0 "orange")
    (make-brick 3 0 "red")
    (make-brick 4 0 "red")
    (make-brick 0 0 "green")
    (make-brick 1 0 "green")
    (make-brick 5 0 "dark green")
    (make-brick 6 0 "dark green")
    (make-brick 7 0 "dark green")
    (make-brick 8 0 "dark green")
    (make-brick 9 0 "dark green"))
   (list (make-brick 2 1 "orange")
         (make-brick 3 1 "orange")
         (make-brick 4 1 "red")
         (make-brick 5 1 "red")
         (make-brick 0 1 "green")
         (make-brick 1 1 "green"))
   (list (make-brick 2 2 "orange"))
   '() '() '() '() '() '() '() '() '() '() '() '() '() '() '() '() '()))
(define lolob3 (list (list (make-brick 0 0 "grey") (make-brick 1 0 "grey"))
                     '() '() '() '() '() '() '() '() '() '() '() '() '() '() '() '() '() '() '()))

; TEMPLATES:
;----------------------------------------------------------------------------------------------------
;                                                                 
;                                                                 
;  ;;;;;;; ;;;;; ;;  ;;  ;;;;;  ;        ;;  ;;;;;;; ;;;;;   ;;;; 
;     ;    ;     ;;  ;;  ;    ; ;        ;;     ;    ;      ;;   ;
;     ;    ;     ;;  ;;  ;    ; ;        ;;     ;    ;      ;     
;     ;    ;     ; ;; ;  ;   ;; ;       ;  ;    ;    ;      ;;    
;     ;    ;;;;; ; ;; ;  ;;;;;  ;       ;  ;    ;    ;;;;;   ;;;; 
;     ;    ;     ;    ;  ;      ;       ;  ;    ;    ;           ;
;     ;    ;     ;    ;  ;      ;       ;;;;    ;    ;           ;
;     ;    ;     ;    ;  ;      ;      ;    ;   ;    ;      ;    ;
;     ;    ;;;;; ;    ;  ;      ;;;;;; ;    ;   ;    ;;;;;   ;;;; 
;                                                                 
;                                                                 
;                                                                 

; world-temp : World -> ?
#; (define (world-temp w)
     (... (piece-temp (world-piece w)) ...
          (lob-temp (world-lob w)) ...
          (world-score w)))

; piece-temp : Piece -> ?
#; (define (piece-temp p)
     (... (nelob-temp (piece-lob p)) ...
          (posn-temp (piece-center p)) ...))

; nelob-temp : NElob -> ?
#; (define (nelob-temp nelob)
     (cond [(empty? (rest nelob)) ... (brick-temp (first nelob)) ...]
           [(cons? (rest nelob)) ... (brick-temp (first nelob)) ... (nelob-temp (rest nelob)) ...]))

; lob-temp : LOB -> ?
#; (define (lob-temp lob)
     (cond [(empty? lob) ...]
           [(cons? lob) ... (brick-temp (first lob)) ... (lob-temp (rest lob)) ...]))

; brick-temp : Brick -> ?
#; (define (brick-temp b)
     (... (brick-x b) ... (brick-y b) ... (brick-color b) ...))

; posn-temp : Posn -> ?
#; (define (posn-temp p)
     (... (posn-x p) ... (posn-y p) ...))

; tn-temp : TypeNumber -> ?
#; (define (tn-temp tn)
     (... tn ...))

; rows-temp : Rows -> ?
#; (define (rows-temp r)
     (... r ...))

; prob-temp : Probability -> ?
#; (define (prob-temp p)
     (... p ...))

; lolob-temp : [List-of LOB] -> ?
#; (define (lolob-temp lolob)
     (cond [(empty? lolob) ...]
           [(cons? lolob) ... (lob-temp (first lolob)) ... (lolob-temp (rest lolob)) ...]))

;----------------------------------------------------------------------------------------------------
; WISHLIST
;----------------------------------------------------------------------------------------------------

;                                                          
;                                                          
;  ;     ; ;;;;;   ;;;;  ;   ;  ;      ;;;;;   ;;;; ;;;;;;;
;  ;     ;   ;    ;;   ; ;   ;  ;        ;    ;;   ;   ;   
;  ;  ;  ;   ;    ;      ;   ;  ;        ;    ;        ;   
;  ;;; ;;;   ;    ;;     ;   ;  ;        ;    ;;       ;   
;   ;; ;;    ;     ;;;;  ;;;;;  ;        ;     ;;;;    ;   
;   ;; ;;    ;         ; ;   ;  ;        ;         ;   ;   
;   ;; ;;    ;         ; ;   ;  ;        ;         ;   ;   
;   ;; ;;    ;    ;    ; ;   ;  ;        ;    ;    ;   ;   
;   ;   ;  ;;;;;   ;;;;  ;   ;  ;;;;;; ;;;;;   ;;;;    ;   
;                                                          
;                                                          
;                                                          

; world->scene : World -> Scene *
; piece->scene : Piece -> Scene *

; world->world : World -> World *
; change-y-piece : Piece -> Piece *
; change-y-lob : LOB -> LOB *
; change-y-brick : Brick -> Brick *
; below? : World -> Boolean *

; key-handler : World KeyEvent -> World *
; shift-world-left : World -> World *
; shift-world-right : World -> World *
; brick-rotate-ccw : Posn Brick -> Brick *
; brick-rotate-cw : Posn Brick -> Brick *
; rotation-past-wall? : World -> Boolean *
; hit-wall? : World -> Boolean ;;;;;;;;;; this one was split into the 2 functions below
; hit-right-wall? : World -> Boolean *
; hit-left-wall? : World -> Boolean *

;----------------------------------------------------------------------------------------------------
; Creating Tetris Pieces by Type
;----------------------------------------------------------------------------------------------------


;                                                                                                    
;                                                                                                    
;             ;                                                             ;       ;                
;                                                                           ;                        
;   ;;;;    ;;;    ;;;    ;;;    ;;;           ;;;    ;;;;   ;;;   ;;;;   ;;;;;   ;;;    ;;;   ; ;;  
;   ;; ;;     ;   ;;  ;  ;;  ;  ;;  ;         ;;  ;   ;;  ; ;;  ;      ;    ;       ;   ;; ;;  ;;  ; 
;   ;   ;     ;   ;   ;; ;      ;   ;;        ;       ;     ;   ;;     ;    ;       ;   ;   ;  ;   ; 
;   ;   ;     ;   ;;;;;; ;      ;;;;;;        ;       ;     ;;;;;;  ;;;;    ;       ;   ;   ;  ;   ; 
;   ;   ;     ;   ;      ;      ;             ;       ;     ;      ;   ;    ;       ;   ;   ;  ;   ; 
;   ;; ;;     ;   ;      ;;     ;             ;;      ;     ;      ;   ;    ;       ;   ;; ;;  ;   ; 
;   ;;;;    ;;;;;  ;;;;   ;;;;   ;;;;          ;;;;   ;      ;;;;   ;;;;    ;;;   ;;;;;  ;;;   ;   ; 
;   ;                                                                                                
;   ;                                                                                                
;   ;                                                                                                


; make-o : Nat Nat -> Piece
; creates an "O" tetris piece with a center at the requested coordinates
(check-expect (make-o 0 0) (make-piece (list (make-brick 0 0 "green")
                                             (make-brick 1 0 "green")
                                             (make-brick 0 1 "green")
                                             (make-brick 1 1 "green")) (make-posn 0 0)))
(check-expect (make-o 2 2) (make-piece (list (make-brick 2 2 "green")
                                             (make-brick 3 2 "green")
                                             (make-brick 2 3 "green")
                                             (make-brick 3 3 "green")) (make-posn 2 2)))

(define (make-o x y)
  (make-piece (list
               (make-brick x y "green")
               (make-brick (+ x 1) y "green")
               (make-brick x (+ y 1) "green")
               (make-brick (+ x 1) (+ y 1) "green"))
              (make-posn x y)))

; make-i : Nat Nat -> Piece
; creates an "I" tetris piece with a center at the requested coordinates
(check-expect (make-i 2 8) (make-piece (list (make-brick 1 8 "blue")
                                             (make-brick 2 8 "blue")
                                             (make-brick 3 8 "blue")
                                             (make-brick 4 8 "blue")) (make-posn 2 8)))
(check-expect (make-i 0 0) (make-piece (list (make-brick -1 0 "blue")
                                             (make-brick 0 0 "blue")
                                             (make-brick 1 0 "blue")
                                             (make-brick 2 0 "blue")) (make-posn 0 0)))

(define (make-i x y)
  (make-piece (list
               (make-brick (- x 1) y "blue")
               (make-brick x y "blue")
               (make-brick (+ x 1) y "blue")
               (make-brick (+ x 2) y "blue"))
              (make-posn x y)))

; make-l : Nat Nat -> Piece
; creates an "L" tetris piece with a center at the requested coordinates
(check-expect (make-l 0 0) (make-piece (list (make-brick -1 0 "purple")
                                             (make-brick 0 0 "purple")
                                             (make-brick 1 0 "purple")
                                             (make-brick 1 1 "purple")) (make-posn 0 0)))
(check-expect (make-l 1 1) (make-piece (list (make-brick 0 1 "purple")
                                             (make-brick 1 1 "purple")
                                             (make-brick 2 1 "purple")
                                             (make-brick 2 2 "purple")) (make-posn 1 1)))

(define (make-l x y)
  (make-piece (list
               (make-brick (- x 1) y "purple")
               (make-brick x y "purple")
               (make-brick (+ x 1) y "purple")
               (make-brick (+ x 1) (+ y 1) "purple"))
              (make-posn x y)))

; make-j : Nat Nat -> Piece
; creates an "J" tetris piece with a center at the requested coordinates
(check-expect (make-j 4 8) (make-piece (list (make-brick 3 9 "cyan")
                                             (make-brick 3 8 "cyan")
                                             (make-brick 4 8 "cyan")
                                             (make-brick 5 8 "cyan")) (make-posn 4 8)))
(check-expect (make-j 0 0) (make-piece (list (make-brick -1 1 "cyan")
                                             (make-brick -1 0 "cyan")
                                             (make-brick 0 0 "cyan")
                                             (make-brick 1 0 "cyan")) (make-posn 0 0)))

(define (make-j x y)
  (make-piece (list
               (make-brick (- x 1) (+ y 1) "cyan")
               (make-brick (- x 1) y "cyan")
               (make-brick x y "cyan")
               (make-brick (+ x 1) y "cyan"))
              (make-posn x y)))

; make-t : Nat Nat -> Piece
; creates an "T" tetris piece with a center at the requested coordinates
(check-expect (make-t 0 0) (make-piece (list (make-brick -1 0 "orange")
                                             (make-brick 0 0 "orange")
                                             (make-brick 0 1 "orange")
                                             (make-brick 1 0 "orange")) (make-posn 0 0)))
(check-expect (make-t 8 10) (make-piece (list (make-brick 7 10 "orange")
                                              (make-brick 8 10 "orange")
                                              (make-brick 8 11 "orange")
                                              (make-brick 9 10 "orange")) (make-posn 8 10)))

(define (make-t x y)
  (make-piece (list
               (make-brick (- x 1) y "orange")
               (make-brick x y "orange")
               (make-brick x (+ y 1) "orange")
               (make-brick (+ x 1) y "orange"))
              (make-posn x y))) 

; make-z : Nat Nat -> Piece
; creates an "Z" tetris piece with a center at the requested coordinates
(check-expect (make-z 4 4) (make-piece (list (make-brick 3 4 "pink")
                                             (make-brick 4 4 "pink")
                                             (make-brick 4 3 "pink")
                                             (make-brick 5 3 "pink")) (make-posn 4 4)))
(check-expect (make-z 0 0) (make-piece (list (make-brick -1 0 "pink")
                                             (make-brick 0 0 "pink")
                                             (make-brick 0 -1 "pink")
                                             (make-brick 1 -1 "pink")) (make-posn 0 0)))

(define (make-z x y)
  (make-piece (list
               (make-brick (- x 1) y "pink")
               (make-brick x y "pink")
               (make-brick x (- y 1) "pink")
               (make-brick (+ x 1) (- y 1) "pink"))
              (make-posn x y)))

; make-s : Nat Nat -> Piece
; creates an "S" tetris piece with a center at the requested coordinates
(check-expect (make-s 10 19) (make-piece (list (make-brick 9 18 "red")
                                               (make-brick 10 18 "red")
                                               (make-brick 10 19 "red")
                                               (make-brick 11 19 "red")) (make-posn 10 19)))
(check-expect (make-s 0 0) (make-piece (list (make-brick -1 -1 "red")
                                             (make-brick 0 -1 "red")
                                             (make-brick 0 0 "red")
                                             (make-brick 1 0 "red")) (make-posn 0 0)))

(define (make-s x y)
  (make-piece (list
               (make-brick (- x 1) (- y 1) "red")
               (make-brick x (- y 1) "red")
               (make-brick x y "red")
               (make-brick (+ x 1) y "red"))
              (make-posn x y)))

; make-magenta-piece : Nat Nat -> Piece
; creates a "magenta piece" tetris piece with a center at the requested coordinates
(check-expect (make-magenta-piece 0 0)
              (make-piece (list (make-brick 0 0 "magenta")) (make-posn 0 0)))
(check-expect (make-magenta-piece 5 10)
              (make-piece (list (make-brick 5 10 "magenta")) (make-posn 5 10)))

(define (make-magenta-piece x y)
  (make-piece (list (make-brick x y "magenta"))
              (make-posn x y)))

; make-green-i : Nat Nat -> Piece
; creates a "green I" tetris piece with a center at the requested coordinates
(check-expect (make-green-i 0 0) (make-piece (list (make-brick -1 0 "dark green")
                                                   (make-brick 0 0 "dark green")
                                                   (make-brick 1 0 "dark green")
                                                   (make-brick 2 0 "dark green")
                                                   (make-brick 3 0 "dark green"))
                                             (make-posn 0 0)))
(check-expect (make-green-i 9 9) (make-piece (list (make-brick 8 9 "dark green")
                                                   (make-brick 9 9 "dark green")
                                                   (make-brick 10 9 "dark green")
                                                   (make-brick 11 9 "dark green")
                                                   (make-brick 12 9 "dark green"))
                                             (make-posn 9 9)))

(define (make-green-i x y)
  (make-piece (list
               (make-brick (- x 1) y "dark green")
               (make-brick x y "dark green")
               (make-brick (add1 x) y "dark green")
               (make-brick (+ x 2) y "dark green")
               (make-brick (+ x 3) y "dark green"))
              (make-posn x y)))

;----------------------------------------------------------------------------------------------------
; Main Function
;----------------------------------------------------------------------------------------------------

;                                                                                             
;                                                                                             
;  ;;  ;;    ;;   ;;;;; ;;   ;         ;;;;;  ;    ;;;   ;    ;;; ;;;;;;; ;;;;;   ;;;; ;;   ; 
;  ;;  ;;    ;;     ;   ;;   ;         ;      ;    ;;;   ;   ;   ;   ;      ;     ;  ; ;;   ; 
;  ;;  ;;    ;;     ;   ;;;  ;         ;      ;    ;;;;  ;  ;        ;      ;    ;    ;;;;  ; 
;  ; ;; ;   ;  ;    ;   ; ;  ;         ;      ;    ;; ;  ;  ;        ;      ;    ;    ;; ;  ; 
;  ; ;; ;   ;  ;    ;   ; ;; ;         ;;;;;  ;    ;; ;; ;  ;        ;      ;    ;    ;; ;; ; 
;  ;    ;   ;  ;    ;   ;  ; ;         ;      ;    ;;  ; ;  ;        ;      ;    ;    ;;  ; ; 
;  ;    ;   ;;;;    ;   ;  ;;;         ;      ;    ;;  ;;;  ;        ;      ;    ;    ;;  ;;; 
;  ;    ;  ;    ;   ;   ;   ;;         ;      ;    ;;   ;;   ;   ;   ;      ;     ;  ; ;   ;; 
;  ;    ;  ;    ; ;;;;; ;   ;;         ;       ;;;; ;   ;;    ;;;    ;    ;;;;;   ;;;; ;   ;; 
;                                                                                             
;                                                                                             
;                                                                                             

; main : Rows Probability -> String
; player inputs number of a rows and a probability for debris pile, displays score when game is over

(define (main n p)
  (string-append
   "SCORE: "
   (number->string
    (world-score
     (big-bang (make-world (new-piece (random 9)) (random-debris n p) 0)
       [to-draw world->scene]
       [on-tick world->world TICK-RATE]
       [on-key key-handler]
       [stop-when game-over?]
       [close-on-stop #t])))))

;----------------------------------------------------------------------------------------------------
; to-draw/image/scene painting functions
;----------------------------------------------------------------------------------------------------

;                                                   
;                            ;                      
;     ;                      ;                      
;     ;                      ;                      
;   ;;;;;   ;;;           ;;;;   ;;;;  ;;;;  ;     ;
;     ;    ;; ;;         ;; ;;   ;;  ;     ; ;     ;
;     ;    ;   ;         ;   ;   ;         ;  ; ; ; 
;     ;    ;   ;  ;;;;;; ;   ;   ;      ;;;;  ; ; ; 
;     ;    ;   ;         ;   ;   ;     ;   ;  ;; ;; 
;     ;    ;; ;;         ;; ;;   ;     ;   ;  ;; ;; 
;     ;;;   ;;;           ;;;;   ;      ;;;;   ; ;  
;                                                   
;                                                   
;                                                   

; world->scene : World -> Scene
; renders a frame of a tetris game.

(define (world->scene w)
  (beside/align "top"
                (lob+scene (world-lob w) (piece->scene (world-piece w)))
                (score+scene (world-score w))))

; score+scene : Natural -> Image
; renders the current score on an empty scene
(check-expect (score+scene 0) (overlay (text (string-append "SCORE: " (number->string 0)) 12 "black")
                                       (empty-scene 100 100)))
(check-expect (score+scene 10)
              (overlay (text (string-append "SCORE: " (number->string 10)) 12 "black")
                       (empty-scene 100 100)))

(define (score+scene n)
  (overlay (text (string-append "SCORE: " (number->string n)) 12 "black")
           (empty-scene 100 100)))

; piece->scene : Piece -> Scene
; renders a piece on the tetris board.

(define (piece->scene p)
  (draw-piece p BACKGROUND))

; draw-piece : Piece Image -> Image
; draws a piece on a tetris board

(define (draw-piece p i)
  (lob+scene (piece-lob p) i))

; lob+scene : NElob Image -> Image
; adds bricks of a tetris piece to the scene

(define (lob+scene nelob i)
  (foldr brick+scene i nelob))

; brick+scene : Brick Image -> Image
; draws a brick on a scene
 
(define (brick+scene b i)
  (place-image-on-grid (rectangle GRID-SQSIZE GRID-SQSIZE "solid" (brick-color b))
                       (brick-x b) (brick-y b) i))

; place-image-on-grid : Image Number Number Image -> Image
; Just like place-image, but takes x,y in grid coordinates

(define (place-image-on-grid img1 x y img2)
  (place-image img1 
               (+ (* GRID-SQSIZE x) (quotient GRID-SQSIZE 2))
               (- BOARD-HEIGHT/PIX 
                  (+ (* GRID-SQSIZE y) (quotient GRID-SQSIZE 2)))
               img2))


;                                                   
;                                             ;     
;                          ;       ;          ;     
;                          ;                  ;     
;    ;;;   ; ;;          ;;;;;   ;;;    ;;;   ;  ;  
;   ;; ;;  ;;  ;           ;       ;   ;;  ;  ;  ;  
;   ;   ;  ;   ;           ;       ;   ;      ; ;   
;   ;   ;  ;   ;  ;;;;;;   ;       ;   ;      ;;;   
;   ;   ;  ;   ;           ;       ;   ;      ; ;   
;   ;; ;;  ;   ;           ;       ;   ;;     ;  ;  
;    ;;;   ;   ;           ;;;   ;;;;;  ;;;;  ;   ; 
;                                                   
;                                                   
;                                                   

;----------------------------------------------------------------------------------------------------
; on-tick/piece motion functions
;----------------------------------------------------------------------------------------------------
; world->world : World -> World
; changes world on tick.
(check-expect (world->world world1) (make-world (make-piece (list (make-brick 4 2 "blue")
                                                                  (make-brick 5 2 "blue")
                                                                  (make-brick 6 2 "blue")
                                                                  (make-brick 7 2 "blue"))
                                                            (make-posn 5 2)) '() 0))
(check-satisfied (world->world world-below) world?)
(check-satisfied (world->world (make-world (make-piece
                                            (list (make-brick 2 0 "green")
                                                  (make-brick 3 0 "green")
                                                  (make-brick 2 1 "green")
                                                  (make-brick 3 1 "green"))
                                            (make-posn 2 0)) '() 0)) world?)
(check-satisfied (world->world world-full) world?)

(define (world->world w)
  (cond [(reached-bottom? w)
         (make-world (new-piece (random 9))
                     (append (piece-lob (world-piece w)) (world-lob w))
                     (world-score w))]
        [(row-full? w) (clear-full-rows w)]
        [else (make-world (change-y-piece (world-piece w)) (world-lob w) (world-score w))]))

;----------------------------------------------------------------------------------------------------
; Homework 10 Exercise 7 & 8
;----------------------------------------------------------------------------------------------------
;
;                                                                                      
;                                                                                      
;   ;   ; ;     ;   ;;    ;;;          ;;;;;  ;    ;               ;;;;;;   ;;;   ;;;; 
;   ;   ; ;     ;  ; ;   ;;  ;         ;       ;  ;                    ;;  ;     ;    ;
;   ;   ; ;  ;  ;    ;   ;  ;;         ;       ;;;;                    ;   ;     ;    ;
;   ;   ; ;;; ;;;    ;   ; ; ;         ;        ;;                     ;   ;;    ;    ;
;   ;;;;;  ;; ;;     ;   ; ; ;         ;;;;;    ;;                    ;    ;;     ;;;; 
;   ;   ;  ;; ;;     ;   ;;  ;         ;        ;;                    ;   ;  ; ; ;;  ;;
;   ;   ;  ;; ;;     ;   ;   ;         ;       ;  ;                  ;    ;  ;;; ;    ;
;   ;   ;  ;; ;;     ;   ;  ;;         ;       ;  ;   ;;             ;    ;;  ;  ;    ;
;   ;   ;  ;   ;   ;;;;;  ;;;          ;;;;;  ;    ;  ;;            ;      ;;; ;  ;;;; 
;                                                                                      
;                                                                                      
;                                                                                      
;----------------------------------------------------------------------------------------------------
; row full detection
;----------------------------------------------------------------------------------------------------
; row-full? : World -> Boolean
; checks if a row is full of bricks in a frame of tetris
(check-expect (row-full? world-above) #f)
(check-expect (row-full? world-full) #t)

(define (row-full? w)
  (row-full-lolob? (sort-lob (world-lob w))))

; row-full-lolob? : [List-of LOB] -> Boolean
; checks if any of the lists in the lists have 10 bricks
(check-expect (row-full-lolob? lolob2) #t)
(check-expect (row-full-lolob? lolob1) #f)

(define (row-full-lolob? lolob)
  (ormap (lambda (lob) (= (length lob) 10)) lolob))

;----------------------------------------------------------------------------------------------------
; clearing the full rows and dropping rows above
;----------------------------------------------------------------------------------------------------
; clear-full-rows : World -> World
; clears the full rows of bricks and moves the rows above down
(check-expect (clear-full-rows world-left) world-left)
(check-expect (clear-full-rows world-full) (make-world (make-piece (list (make-brick 2 10 "green")
                                                                         (make-brick 2 11 "green")
                                                                         (make-brick 3 10 "green")
                                                                         (make-brick 3 11 "green"))
                                                                   (make-posn 2 10))
                                                       (list (make-brick 2 0 "orange")
                                                             (make-brick 3 0 "orange")
                                                             (make-brick 4 0 "red")
                                                             (make-brick 5 0 "red")
                                                             (make-brick 0 0 "green")
                                                             (make-brick 1 0 "green")
                                                             (make-brick 2 1 "orange")) 10))

(define (clear-full-rows w)
  (make-world (world-piece w)
              (apply append (clear-row-lolob (sort-lob (world-lob w))))
              (+ (add-score w) (world-score w))))

; clear-row-lolob : [List-of LOB] -> [List-of LOB]
; clears a full row of bricks and moves the rows above down
(check-expect (clear-row-lolob lolob1) lolob1)
(check-expect (clear-row-lolob lolob2)
              (list '() (list (make-brick 2 0 "orange") (make-brick 3 0 "orange")
                              (make-brick 4 0 "red") (make-brick 5 0 "red") (make-brick 0 0 "green")
                              (make-brick 1 0 "green"))
                    (list (make-brick 2 1 "orange")) '() '() '() '() '() '() '() '() '() '() '() '()
                    '() '() '() '() '()))

(define (clear-row-lolob lolob)
  (cond [(empty? lolob) lolob]
        [(cons? lolob) (if (= 10 (length (first lolob)))
                           (cons '() (change-y-lolob (clear-row-lolob (rest lolob))))
                           (cons (first lolob) (clear-row-lolob (rest lolob))))]))

; change-y-lolob : [List-of LOB] -> [List-of LOB]
; in a list of lobs, decreases the y values of all the bricks within the lobs by 1
(check-expect (change-y-lolob lolob1) lolob1)
(check-expect (change-y-lolob (rest lolob2))
              (list (list (make-brick 2 0 "orange") (make-brick 3 0 "orange") (make-brick 4 0 "red")
                          (make-brick 5 0 "red") (make-brick 0 0 "green") (make-brick 1 0 "green"))
                    (list (make-brick 2 1 "orange")) '() '() '() '() '() '() '() '() '() '() '() '()
                    '() '() '() '() '()))

(define (change-y-lolob lolob)
  (map change-y-lob lolob))

;----------------------------------------------------------------------------------------------------
; sorting lob into ordered rows
;----------------------------------------------------------------------------------------------------
; sort-lob : LOB -> [List-of LOB]
; for a pile of bricks, sorts them into a list of 20 lists based on their row value on a tetris board
(check-expect (sort-lob pile4) lolob2)
(check-expect (sort-lob pile1) lolob1)

(define (sort-lob lob)
  (local [; filter-bricks-in-row : Rows -> LOB
          ; makes a list of bricks that are in the same row as the given "Rows"
          (define (filter-bricks-in-row r)
            (filter (lambda (b) (= (brick-y b) r)) lob))]
    (list (filter-bricks-in-row 0)
          (filter-bricks-in-row 1)
          (filter-bricks-in-row 2)
          (filter-bricks-in-row 3)
          (filter-bricks-in-row 4)
          (filter-bricks-in-row 5)
          (filter-bricks-in-row 6)
          (filter-bricks-in-row 7)
          (filter-bricks-in-row 8)
          (filter-bricks-in-row 9)
          (filter-bricks-in-row 10)
          (filter-bricks-in-row 11)
          (filter-bricks-in-row 12)
          (filter-bricks-in-row 13)
          (filter-bricks-in-row 14)
          (filter-bricks-in-row 15)
          (filter-bricks-in-row 16)
          (filter-bricks-in-row 17)
          (filter-bricks-in-row 18)
          (filter-bricks-in-row 19))))

;----------------------------------------------------------------------------------------------------
; score calculations
;----------------------------------------------------------------------------------------------------
; add-score : World -> Natural
; determines score based on how many rows are full in a world state
(check-expect (add-score world1) 0)
(check-expect (add-score world-full) 10)

(define (add-score w)
  (local [; score-calculator : Natural -> Natural
          ; calculates score based on how many rows are cleared (how many are full)
          (define (score-calculator n)
            (* 10 (sqr n)))]
    (score-calculator (how-many-full-rows-lolob (sort-lob (world-lob w))))))

; how-many-full-rows-lolob : [List-of LOB] -> Natural
; checks how many rows are full in order to calculate the score
(check-expect (how-many-full-rows-lolob lolob1) 0)
(check-expect (how-many-full-rows-lolob lolob2) 1)

(define (how-many-full-rows-lolob lolob)
  (length (filter (lambda (lob) (= (length lob) 10)) lolob)))
 
;----------------------------------------------------------------------------------------------------
; end of homework 10, exercise 7 & 8
;----------------------------------------------------------------------------------------------------
;                                                          
;                                                          
;   ;;;;; ;;   ;  ;;;;          ;   ; ;     ;   ;;    ;;;  
;   ;     ;;   ;  ;   ;         ;   ; ;     ;  ; ;   ;;  ; 
;   ;     ;;;  ;  ;    ;        ;   ; ;  ;  ;    ;   ;  ;; 
;   ;     ; ;  ;  ;    ;        ;   ; ;;; ;;;    ;   ; ; ; 
;   ;;;;; ; ;; ;  ;    ;        ;;;;;  ;; ;;     ;   ; ; ; 
;   ;     ;  ; ;  ;    ;        ;   ;  ;; ;;     ;   ;;  ; 
;   ;     ;  ;;;  ;    ;        ;   ;  ;; ;;     ;   ;   ; 
;   ;     ;   ;;  ;   ;         ;   ;  ;; ;;     ;   ;  ;; 
;   ;;;;; ;   ;;  ;;;;          ;   ;  ;   ;   ;;;;;  ;;;  
;                                                          
;                                                          
;

;----------------------------------------------------------------------------------------------------
; piece movement functions (decrease y coord by 1)
;----------------------------------------------------------------------------------------------------
; change-y-piece : Piece -> Piece
; decreases the y grid coordinate of a piece by one and changes the center to reflect it.
(check-expect (change-y-piece o-piece-example)
              (make-piece (list (make-brick 2 9 "green")
                                (make-brick 2 10 "green")
                                (make-brick 3 9 "green")
                                (make-brick 3 10 "green")) (make-posn 2 9)))
(check-expect (change-y-piece i-piece-example)
              (make-piece (list (make-brick 4 2 "blue")
                                (make-brick 5 2 "blue")
                                (make-brick 6 2 "blue")
                                (make-brick 7 2 "blue")) (make-posn 5 2)))

(define (change-y-piece p)
  (make-piece (change-y-lob (piece-lob p))
              (make-posn (posn-x (piece-center p)) (- (posn-y (piece-center p)) 1))))

; change-y-lob : NElob -> NElob
; decreases the y grid coordinates of a list of bricks by 1 grid coordinate
(check-expect (change-y-lob lob1) (list (make-brick 4 2 "blue")
                                        (make-brick 5 2 "blue")
                                        (make-brick 6 2 "blue")
                                        (make-brick 7 2 "blue")))
(check-expect (change-y-lob lob2) (list (make-brick 2 9 "green")
                                        (make-brick 2 10 "green")
                                        (make-brick 3 9 "green")
                                        (make-brick 3 10 "green")))

(define (change-y-lob lob)
  (map change-y-brick lob))

; change-y-brick : Brick -> Brick
; decreases y grid coordinate of a brick
(check-expect (change-y-brick brick1) (make-brick 4 2 "blue"))
(check-expect (change-y-brick brick6) (make-brick 2 10 "green"))

(define (change-y-brick b)
  (make-brick (brick-x b) (- (brick-y b) 1) (brick-color b)))

;----------------------------------------------------------------------------------------------------
; stop piece detection functions (hit bottom)
;----------------------------------------------------------------------------------------------------
; reached-bottom? : World -> Boolean
; did the world reach the bottom of the board or hit the pile of bricks at the bottom?
(check-expect (reached-bottom? world1) #f)
(check-expect (reached-bottom? (make-world (make-piece
                                            (list (make-brick 2 0 "green")
                                                  (make-brick 3 0 "green")
                                                  (make-brick 2 1 "green")
                                                  (make-brick 3 1 "green"))
                                            (make-posn 2 0)) '() 0)) #t)

(define (reached-bottom? w)
  (or (piece-reached-bottom? (world-piece w))
      (piece-touched-lob? (world-piece w) (world-lob w))))

; piece-reached-bottom? : Piece -> Boolean
; did the piece reach the bottom of the board?
(check-expect (piece-reached-bottom? (make-piece (list (make-brick 2 0 "green")
                                                       (make-brick 3 0 "green")
                                                       (make-brick 2 1 "green")
                                                       (make-brick 3 1 "green"))
                                                 (make-posn 2 0))) #t)
(check-expect (piece-reached-bottom? o-piece-example) #f)

(define (piece-reached-bottom? p)
  (lob-reached-bottom? (piece-lob p)))

; lob-reached-bottom? : NElob -> Boolean
; did the lob reach the bottom of the board?
(check-expect (lob-reached-bottom? (list (make-brick 2 0 "green")
                                         (make-brick 3 0 "green")
                                         (make-brick 2 1 "green")
                                         (make-brick 3 1 "green"))) #t)
(check-expect (lob-reached-bottom? lob1) #f)

(define (lob-reached-bottom? lob)
  (ormap (lambda (b) (= (brick-y b) 0)) lob))

; piece-touched-lob? : Piece LOB -> Boolean
; did the piece touch a brick in the pile of bricks already at the bottom?
(check-expect (piece-touched-lob? o-piece-example '()) #f)
(check-expect (piece-touched-lob? (make-piece (list (make-brick 2 2 "purple")
                                                    (make-brick 3 2 "purple")
                                                    (make-brick 4 2 "purple")
                                                    (make-brick 4 3 "purple")) (make-posn 3 2))
                                  (list (make-brick 2 1 "pink") (make-brick 3 1 "pink")
                                        (make-brick 3 0 "pink") (make-brick 4 0 "pink"))) #t)

(define (piece-touched-lob? p pile)
  (lob-touched-lob? (piece-lob p) pile))

; lob-touched-lob? : NElob LOB -> Boolean
; did any of the bricks in the piece touch the pile of bricks at the bottom?
(check-expect (lob-touched-lob? (list (make-brick 2 2 "purple")
                                      (make-brick 3 2 "purple")
                                      (make-brick 4 2 "purple")
                                      (make-brick 4 3 "purple"))
                                (list (make-brick 2 1 "pink") (make-brick 3 1 "pink")
                                      (make-brick 3 0 "pink") (make-brick 4 0 "pink"))) #t)
(check-expect (lob-touched-lob? lob1 '()) #f)

(define (lob-touched-lob? p-lob pile)
  (ormap (lambda (b) (brick-touched-lob? b pile)) p-lob))

; brick-touched-lob? : Brick LOB -> Boolean
; did the brick touch a brick in the pile of bricks already at the bottom?
(check-expect (brick-touched-lob? brick1 '()) #f)
(check-expect (brick-touched-lob? (make-brick 2 2 "purple")
                                  (list (make-brick 2 1 "pink") (make-brick 3 1 "pink")
                                        (make-brick 3 0 "pink") (make-brick 4 0 "pink"))) #t)

(define (brick-touched-lob? b pile)
  (local [; pile-brick-touched-brick? : Brick -> Boolean
          ; did a brick in the pile touch the top of a given brick?
          (define (pile-brick-touched-brick? b2)
            (and (= (brick-x b) (brick-x b2))
                 (= (brick-y b) (add1 (brick-y b2)))))]
    (ormap pile-brick-touched-brick? pile)))
        
;----------------------------------------------------------------------------------------------------
; key handler functions
;----------------------------------------------------------------------------------------------------

;                                            
;                        ;                   
;                        ;                   
;                        ;                   
;    ;;;   ; ;;          ;  ;    ;;;   ;   ; 
;   ;; ;;  ;;  ;         ;  ;   ;;  ;  ;   ; 
;   ;   ;  ;   ;         ; ;    ;   ;;  ; ;  
;   ;   ;  ;   ;  ;;;;;; ;;;    ;;;;;;  ; ;  
;   ;   ;  ;   ;         ; ;    ;       ; ;  
;   ;; ;;  ;   ;         ;  ;   ;       ;;   
;    ;;;   ;   ;         ;   ;   ;;;;    ;   
;                                        ;   
;                                       ;    
;                                      ;;    
                                                                
; key-handler : World KeyEvent -> World
; when left key is pressed, piece shifts left; when right key is pressed, piece shifts right;
; when a is pressed, piece rotates counter-clockwise;
; when s is pressed, piece rotates clockwise.
(check-expect (key-handler world1 "t") world1)
(check-expect (key-handler world1 "left")
              (make-world (make-piece (list (make-brick 3 3 "blue")
                                            (make-brick 4 3 "blue")
                                            (make-brick 5 3 "blue")
                                            (make-brick 6 3 "blue")) (make-posn 4 3)) '() 0))
(check-expect (key-handler world1 "right")
              (make-world (make-piece (list (make-brick 5 3 "blue")
                                            (make-brick 6 3 "blue")
                                            (make-brick 7 3 "blue")
                                            (make-brick 8 3 "blue")) (make-posn 6 3)) '() 0))
(check-expect (key-handler world-left "left") world-left)
(check-expect (key-handler world-right "right") world-right)
(check-expect (key-handler world1 "a") (make-world
                                        (make-piece
                                         (list (make-brick 5 2 "blue")
                                               (make-brick 5 3 "blue")
                                               (make-brick 5 4 "blue")
                                               (make-brick 5 5 "blue")) (make-posn 5 3)) '() 0))
(check-expect (key-handler world1 "s") (make-world
                                        (make-piece
                                         (list (make-brick 5 4 "blue")
                                               (make-brick 5 3 "blue")
                                               (make-brick 5 2 "blue")
                                               (make-brick 5 1 "blue")) (make-posn 5 3)) '() 0))
(check-expect (key-handler world-left "a") world-left)
(check-expect (key-handler world-right "s") world-right)

(define (key-handler w ke)
  (local [; wall-hit : [World -> Boolean] [World -> Boolean] [World -> World] -> World
          ; if the world returns true for the either of first 2 functions, world stays the same
          ; otherwise, the third function is used to change the world.
          (define (wall-hit f1 f2 f3)
            (if (or (f1 w) (f2 w)) w (f3 w)))]
    (cond [(key=? "left" ke) (wall-hit hit-left-wall? hit-brick-left? shift-world-left)]
          [(key=? "right" ke) (wall-hit hit-right-wall? hit-brick-right? shift-world-right)]
          [(key=? "a" ke) (wall-hit rotation-past-wall? rotation-into-pile? world-rotate-ccw)]
          [(key=? "s" ke) (wall-hit rotation-past-wall? rotation-into-pile? world-rotate-cw)]
          [else w])))

;----------------------------------------------------------------------------------------------------
; "left" key handler motion functions
;----------------------------------------------------------------------------------------------------
; shift-world-left : World -> World
; shifts a tetris piece left by 1 grid coordinate
(check-expect (shift-world-left world1)
              (make-world (make-piece
                           (list (make-brick 3 3 "blue")
                                 (make-brick 4 3 "blue")
                                 (make-brick 5 3 "blue")
                                 (make-brick 6 3 "blue")) (make-posn 4 3)) '() 0))
(check-expect (shift-world-left world2)
              (make-world (make-piece
                           (list (make-brick 1 10 "green")
                                 (make-brick 1 11 "green")
                                 (make-brick 2 10 "green")
                                 (make-brick 2 11 "green")) (make-posn 1 10)) '() 0))

(define (shift-world-left w)
  (make-world (shift-piece-left (world-piece w)) (world-lob w) (world-score w)))

; shift-piece-left : Piece -> Piece
; shifts tetris piece left by 1 grid coordinate
(check-expect (shift-piece-left i-piece-example)
              (make-piece (list (make-brick 3 3 "blue")
                                (make-brick 4 3 "blue")
                                (make-brick 5 3 "blue")
                                (make-brick 6 3 "blue")) (make-posn 4 3)))
(check-expect (shift-piece-left o-piece-example)
              (make-piece (list (make-brick 1 10 "green")
                                (make-brick 1 11 "green")
                                (make-brick 2 10 "green")
                                (make-brick 2 11 "green")) (make-posn 1 10)))

(define (shift-piece-left p)
  (make-piece (shift-lob-left (piece-lob p))
              (make-posn (- (posn-x (piece-center p)) 1) (posn-y (piece-center p)))))

; shift-lob-left : NElob -> NElob
; shifts an lob left by 1 grid coordinate
(check-expect (shift-lob-left lob1) (list (make-brick 3 3 "blue")
                                          (make-brick 4 3 "blue")
                                          (make-brick 5 3 "blue")
                                          (make-brick 6 3 "blue")))
(check-expect (shift-lob-left lob2) (list (make-brick 1 10 "green")
                                          (make-brick 1 11 "green")
                                          (make-brick 2 10 "green")
                                          (make-brick 2 11 "green")))

(define (shift-lob-left lob)
  (local [; make-brick-left : Brick -> Brick
          ; makes a brick 1 grid square to the left of original brick
          (define (make-brick-left b)
            (make-brick (- (brick-x b) 1) (brick-y b) (brick-color b)))]
    (map make-brick-left lob)))

;----------------------------------------------------------------------------------------------------
;; "right" key handler motion functions
;----------------------------------------------------------------------------------------------------
; shift-world-right : World -> World
; shifts a tetris piece right by 1 grid coordinate
(check-expect (shift-world-right world1)
              (make-world (make-piece
                           (list (make-brick 5 3 "blue")
                                 (make-brick 6 3 "blue")
                                 (make-brick 7 3 "blue")
                                 (make-brick 8 3 "blue")) (make-posn 6 3)) '() 0))
(check-expect (shift-world-right world2)
              (make-world (make-piece
                           (list (make-brick 3 10 "green")
                                 (make-brick 3 11 "green")
                                 (make-brick 4 10 "green")
                                 (make-brick 4 11 "green")) (make-posn 3 10)) '() 0))
              
(define (shift-world-right w)
  (make-world (shift-piece-right (world-piece w)) (world-lob w) (world-score w)))

; shift-piece-right : Piece -> Piece
; shifts a tetris piece right by 1 grid coordinate
(check-expect (shift-piece-right o-piece-example)
              (make-piece (list (make-brick 3 10 "green")
                                (make-brick 3 11 "green")
                                (make-brick 4 10 "green")
                                (make-brick 4 11 "green")) (make-posn 3 10)))
(check-expect (shift-piece-right i-piece-example)
              (make-piece (list (make-brick 5 3 "blue")
                                (make-brick 6 3 "blue")
                                (make-brick 7 3 "blue")
                                (make-brick 8 3 "blue")) (make-posn 6 3)))

(define (shift-piece-right p)
  (make-piece (shift-lob-right (piece-lob p))
              (make-posn (+ (posn-x (piece-center p)) 1) (posn-y (piece-center p)))))

; shift-lob-right : NElob -> NElob
; shifts an lob right by 1 grid coordinate
(check-expect (shift-lob-right lob1) (list (make-brick 5 3 "blue")
                                           (make-brick 6 3 "blue")
                                           (make-brick 7 3 "blue")
                                           (make-brick 8 3 "blue")))
(check-expect (shift-lob-right lob2) (list (make-brick 3 10 "green")
                                           (make-brick 3 11 "green")
                                           (make-brick 4 10 "green")
                                           (make-brick 4 11 "green")))

(define (shift-lob-right lob)
  (local [; make-brick-right : Brick -> Brick
          ; makes a brick 1 grid square to the right of original brick
          (define (make-brick-right b)
            (make-brick (+ (brick-x b) 1) (brick-y b) (brick-color b)))]
    (map make-brick-right lob)))

;----------------------------------------------------------------------------------------------------
;; touching left wall detection
;----------------------------------------------------------------------------------------------------
; hit-left-wall? : World -> Boolean
; did the piece hit the left edge of the board?
(check-expect (hit-left-wall? world1) #f)
(check-expect (hit-left-wall? world-left) #t)

(define (hit-left-wall? w)
  (piece-hit-left-wall? (world-piece w)))

; piece-hit-left-wall? : Piece -> Boolean
; did the piece hit the left edge of the board?
(check-expect (piece-hit-left-wall? o-piece-example) #f)
(check-expect (piece-hit-left-wall? piece-left) #t)

(define (piece-hit-left-wall? p)
  (lob-hit-left-wall? (piece-lob p)))

; lob-hit-left-wall? : NElob -> Boolean
; did the NElob hit the left edge of the board?
(check-expect (lob-hit-left-wall? lob1) #f)
(check-expect (lob-hit-left-wall? lob-left) #t)

(define (lob-hit-left-wall? lob)
  (ormap (lambda (b) (= (brick-x b) 0)) lob))

;----------------------------------------------------------------------------------------------------
;; touching right wall detection
;----------------------------------------------------------------------------------------------------
; hit-right-wall? : World -> Boolean
; did the piece hit the right edge of the board?
(check-expect (hit-right-wall? world1) #f)
(check-expect (hit-right-wall? world-right) #t)

(define (hit-right-wall? w)
  (piece-hit-right-wall? (world-piece w)))

; piece-hit-right-wall? : Piece -> Boolean
; did the piece hit the right edge of the board?
(check-expect (piece-hit-right-wall? o-piece-example) #f)
(check-expect (piece-hit-right-wall? piece-right) #t)

(define (piece-hit-right-wall? p)
  (lob-hit-right-wall? (piece-lob p)))

; lob-hit-right-wall? : NElob -> Boolean
; did the NElob hit the right edge of the board?
(check-expect (lob-hit-right-wall? lob1) #f)
(check-expect (lob-hit-right-wall? lob-right) #t)

(define (lob-hit-right-wall? lob)
  (ormap (lambda (b) (= (brick-x b) 9)) lob))

;----------------------------------------------------------------------------------------------------
;; hit another brick to the left detection
;----------------------------------------------------------------------------------------------------
; hit-brick-left? : World -> Boolean
; is there a brick in the pile directly to the left of the piece?
(check-expect (hit-brick-left? (make-world (make-piece
                                            (list (make-brick 2 0 "green")
                                                  (make-brick 3 0 "green")
                                                  (make-brick 2 1 "green")
                                                  (make-brick 3 1 "green")) (make-posn 2 0))
                                           (list (make-brick 0 0 "green")
                                                 (make-brick 1 0 "green")
                                                 (make-brick 0 1 "green")
                                                 (make-brick 1 1 "green")) 0)) #t)
(check-expect (hit-brick-left? world1) #f)

(define (hit-brick-left? w)
  (piece-hit-pile-left? (world-piece w) (world-lob w)))

; piece-hit-pile-left? : Piece LOB -> Boolean
; is there a brick in the pile directly to the left of the piece?
(check-expect (piece-hit-pile-left? (make-piece
                                     (list (make-brick 2 0 "green")
                                           (make-brick 3 0 "green")
                                           (make-brick 2 1 "green")
                                           (make-brick 3 1 "green")) (make-posn 2 0))
                                    (list (make-brick 0 0 "green")
                                          (make-brick 1 0 "green")
                                          (make-brick 0 1 "green")
                                          (make-brick 1 1 "green"))) #t)
(check-expect (piece-hit-pile-left? i-piece-example '()) #f)

(define (piece-hit-pile-left? p pile)
  (nelob-hit-pile-left? (piece-lob p) pile))

; nelob-hit-pile-left? : NElob LOB -> Boolean
; is there a brick in the pile directly to the left of the list of the bricks?
(check-expect (nelob-hit-pile-left? (list (make-brick 2 0 "green")
                                          (make-brick 3 0 "green")
                                          (make-brick 2 1 "green")
                                          (make-brick 3 1 "green"))
                                    (list (make-brick 0 0 "green")
                                          (make-brick 1 0 "green")
                                          (make-brick 0 1 "green")
                                          (make-brick 1 1 "green"))) #t)
(check-expect (nelob-hit-pile-left? lob1 '()) #f)

(define (nelob-hit-pile-left? nelob pile)
  (ormap (lambda (b) (brick-hit-brick-left? b pile)) nelob))

; brick-hit-brick-left? : Brick LOB -> Boolean
; is there a brick in the pile directly to the left of the brick?
(check-expect (brick-hit-brick-left? (make-brick 2 0 "green")
                                     (list (make-brick 0 0 "green")
                                           (make-brick 1 0 "green")
                                           (make-brick 0 1 "green")
                                           (make-brick 1 1 "green"))) #t)
(check-expect (brick-hit-brick-left? brick1 '()) #f)

(define (brick-hit-brick-left? b pile)
  (local [; pile-brick-left? : Brick -> Boolean
          ; is there a brick in the pile to the left of the given brick?
          (define (pile-brick-left? b2)
            (and (= (brick-y b) (brick-y b2))
                 (= (brick-x b) (add1 (brick-x b2)))))]
    (ormap pile-brick-left? pile)))

;----------------------------------------------------------------------------------------------------
;; hit another brick to the right detection
;----------------------------------------------------------------------------------------------------
; hit-brick-right? : World -> Boolean
; is there a brick in the pile directly to the right of the piece?
(check-expect (hit-brick-right? (make-world (make-piece (list (make-brick 8 1 "purple")
                                                              (make-brick 8 2 "purple")
                                                              (make-brick 8 3 "purple")
                                                              (make-brick 7 3 "purple"))
                                                        (make-posn 8 2))
                                            (list (make-brick 8 0 "cyan")
                                                  (make-brick 9 0 "cyan")
                                                  (make-brick 9 1 "cyan")
                                                  (make-brick 9 2 "cyan")) 0)) #t)
(check-expect (hit-brick-right? world1) #f)

(define (hit-brick-right? w)
  (piece-hit-pile-right? (world-piece w) (world-lob w)))

; piece-hit-pile-right? : Piece LOB -> Boolean
; is there a brick in the pile directly to the right of the piece?
(check-expect (piece-hit-pile-right? (make-piece (list (make-brick 8 1 "purple")
                                                       (make-brick 8 2 "purple")
                                                       (make-brick 8 3 "purple")
                                                       (make-brick 7 3 "purple"))
                                                 (make-posn 8 2))
                                     (list (make-brick 8 0 "cyan")
                                           (make-brick 9 0 "cyan")
                                           (make-brick 9 1 "cyan")
                                           (make-brick 9 2 "cyan"))) #t)
(check-expect (piece-hit-pile-right? i-piece-example '()) #f)

(define (piece-hit-pile-right? p pile)
  (nelob-hit-pile-right? (piece-lob p) pile))

; nelob-hit-pile-right? : NElob LOB -> Boolean
; is there a brick directly to the right of the list of the bricks?
(check-expect (nelob-hit-pile-right? (list (make-brick 8 1 "purple")
                                           (make-brick 8 2 "purple")
                                           (make-brick 8 3 "purple")
                                           (make-brick 7 3 "purple"))
                                     (list (make-brick 8 0 "cyan")
                                           (make-brick 9 0 "cyan")
                                           (make-brick 9 1 "cyan")
                                           (make-brick 9 2 "cyan"))) #t)
(check-expect (nelob-hit-pile-right? lob1 '()) #f)

(define (nelob-hit-pile-right? nelob pile)
  (ormap (lambda (b) (brick-hit-brick-right? b pile)) nelob))

; brick-hit-brick-right? : Brick LOB -> Boolean
; is there a brick directly to the right of the brick?
(check-expect (brick-hit-brick-right? (make-brick 8 2 "purple") (list (make-brick 8 0 "cyan")
                                                                      (make-brick 9 0 "cyan")
                                                                      (make-brick 9 1 "cyan")
                                                                      (make-brick 9 2 "cyan"))) #t)
(check-expect (brick-hit-brick-right? brick1 '()) #f)

(define (brick-hit-brick-right? b pile)
  (local [; pile-brick-right? : Brick -> Boolean
          ; is there a brick in the pile to the right of the given brick?
          (define (pile-brick-right? b2)
            (and (= (brick-y b) (brick-y b2))
                 (= (brick-x b) (- (brick-x b2) 1))))]
    (ormap pile-brick-right? pile)))

;----------------------------------------------------------------------------------------------------
;; "a" key counter-clockwise rotation functions
;----------------------------------------------------------------------------------------------------
; world-rotate-ccw : World -> World
; rotates a tetris piece 90 degrees counter-clockwise around the center
(check-expect (world-rotate-ccw world1)
              (make-world (make-piece (list
                                       (make-brick 5 2 "blue")
                                       (make-brick 5 3 "blue")
                                       (make-brick 5 4 "blue")
                                       (make-brick 5 5 "blue")) (make-posn 5 3)) '() 0))
(check-expect (world-rotate-ccw world2)
              (make-world (make-piece (list
                                       (make-brick 2 10 "green")
                                       (make-brick 1 10 "green")
                                       (make-brick 2 11 "green")
                                       (make-brick 1 11 "green")) (make-posn 2 10)) '() 0))

(define (world-rotate-ccw w)
  (make-world (piece-rotate-ccw (world-piece w)) (world-lob w) (world-score w)))

; piece-rotate-ccw : Piece -> Piece
; rotates a tetris piece 90 degrees counter-clockwise around the center
(check-expect (piece-rotate-ccw o-piece-example)
              (make-piece (list (make-brick 2 10 "green")
                                (make-brick 1 10 "green")
                                (make-brick 2 11 "green")
                                (make-brick 1 11 "green")) (make-posn 2 10)))
(check-expect (piece-rotate-ccw i-piece-example)
              (make-piece (list (make-brick 5 2 "blue")
                                (make-brick 5 3 "blue")
                                (make-brick 5 4 "blue")
                                (make-brick 5 5 "blue")) (make-posn 5 3)))

(define (piece-rotate-ccw p)
  (make-piece (lob-rotate-ccw (piece-center p) (piece-lob p))
              (piece-center p)))

; lob-rotate-ccw : Posn NElob -> LOB
; rotates an NElob 90 degrees counter-clockwise around center
(check-expect (lob-rotate-ccw (piece-center o-piece-example) (piece-lob o-piece-example))
              (list (make-brick 2 10 "green")
                    (make-brick 1 10 "green")
                    (make-brick 2 11 "green")
                    (make-brick 1 11 "green")))
(check-expect (lob-rotate-ccw (piece-center i-piece-example) (piece-lob i-piece-example))
              (list (make-brick 5 2 "blue")
                    (make-brick 5 3 "blue")
                    (make-brick 5 4 "blue")
                    (make-brick 5 5 "blue")))

(define (lob-rotate-ccw c lob)
  (map (lambda (b) (brick-rotate-ccw c b)) lob))

; brick-rotate-ccw : Posn Brick -> Brick
; Rotate the brick _b_ 90 degrees counterclockwise around the center _c_.
(check-expect (brick-rotate-ccw (piece-center o-piece-example) (first (piece-lob o-piece-example)))
              (make-brick 2 10 "green"))
(check-expect (brick-rotate-ccw (piece-center i-piece-example) (first (piece-lob i-piece-example)))
              (make-brick 5 2 "blue"))

(define (brick-rotate-ccw c b)
  (make-brick (+ (posn-x c)
                 (- (posn-y c)
                    (brick-y b)))
              (+ (posn-y c)
                 (- (brick-x b)
                    (posn-x c)))
              (brick-color b)))

;----------------------------------------------------------------------------------------------------
;; "s" key clockwise rotation functions
;----------------------------------------------------------------------------------------------------
; world-rotate-cw : World -> World
; rotates a tetris piece 90 degrees clockwise around the center
(check-expect (world-rotate-cw world1)
              (make-world (make-piece (list
                                       (make-brick 5 4 "blue")
                                       (make-brick 5 3 "blue")
                                       (make-brick 5 2 "blue")
                                       (make-brick 5 1 "blue")) (make-posn 5 3)) '() 0))
(check-expect (world-rotate-cw world2)
              (make-world (make-piece (list (make-brick 2 10 "green")
                                            (make-brick 3 10 "green")
                                            (make-brick 2 9 "green")
                                            (make-brick 3 9 "green")) (make-posn 2 10)) '() 0))

(define (world-rotate-cw w)
  (make-world (piece-rotate-cw (world-piece w)) (world-lob w) (world-score w)))

; piece-rotate-cw : Piece -> Piece
; rotates a tetris piece 90 degrees clockwise around the center
(check-expect (piece-rotate-cw o-piece-example)
              (make-piece (list (make-brick 2 10 "green")
                                (make-brick 3 10 "green")
                                (make-brick 2 9 "green")
                                (make-brick 3 9 "green")) (make-posn 2 10)))
(check-expect (piece-rotate-cw i-piece-example)
              (make-piece (list (make-brick 5 4 "blue")
                                (make-brick 5 3 "blue")
                                (make-brick 5 2 "blue")
                                (make-brick 5 1 "blue")) (make-posn 5 3)))

(define (piece-rotate-cw p)
  (make-piece (lob-rotate-cw (piece-center p) (piece-lob p))
              (piece-center p)))

; lob-rotate-cw : Posn NElob -> LOB
; rotates an NElob 90 degrees clockwise around center
(check-expect (lob-rotate-cw (piece-center i-piece-example) (piece-lob i-piece-example))
              (list (make-brick 5 4 "blue")
                    (make-brick 5 3 "blue")
                    (make-brick 5 2 "blue")
                    (make-brick 5 1 "blue")))
(check-expect (lob-rotate-cw (piece-center o-piece-example) (piece-lob o-piece-example))
              (list (make-brick 2 10 "green")
                    (make-brick 3 10 "green")
                    (make-brick 2 9 "green")
                    (make-brick 3 9 "green")))

(define (lob-rotate-cw c lob)
  (map (lambda (b) (brick-rotate-cw c b)) lob))

; brick-rotate-cw : Posn Brick -> Brick
; Rotate the brick _b_ 90 degrees clockwise around the center _c_.
(check-expect (brick-rotate-cw (piece-center o-piece-example) (first (piece-lob o-piece-example)))
              (make-brick 2 10 "green"))
(check-expect (brick-rotate-cw (piece-center i-piece-example) (first (piece-lob i-piece-example)))
              (make-brick 5 4 "blue"))

(define (brick-rotate-cw c b)
  (brick-rotate-ccw c (brick-rotate-ccw c (brick-rotate-ccw c b))))

;----------------------------------------------------------------------------------------------------
;; rotation past tetris board edge detection
;----------------------------------------------------------------------------------------------------
; rotation-past-wall? : World -> Boolean
; does the rotated piece go past the edge of the board?
(check-expect (rotation-past-wall? world-right) #t)
(check-expect (rotation-past-wall? world1) #f)

(define (rotation-past-wall? w)
  (piece-rotation-past-wall? (world-piece w))) 

; piece-rotation-past-wall? : Piece -> Boolean
; does the rotated piece go past the edge of the board?
(check-expect (piece-rotation-past-wall? o-piece-example) #f)
(check-expect (piece-rotation-past-wall? piece-right) #t)

(define (piece-rotation-past-wall? p)
  (lob-rotation-past-wall? (piece-center p) (piece-lob p)))

; lob-rotation-past-wall? : Posn NElob -> Boolean
; does the rotated lob go past the edge of the board?
(check-expect (lob-rotation-past-wall? (piece-center o-piece-example) (piece-lob o-piece-example)) #f)
(check-expect (lob-rotation-past-wall? (piece-center piece-right) (piece-lob piece-right)) #t)
               
(define (lob-rotation-past-wall? c lob)
  (ormap (lambda (b) (brick-rotation-past-wall? c b)) lob))

; brick-rotation-past-wall? : Posn Brick -> Boolean
; does the rotated brick go past the edge of the board?
(check-expect (brick-rotation-past-wall? (piece-center o-piece-example)
                                         (first (piece-lob o-piece-example))) #f)
(check-expect (brick-rotation-past-wall? (piece-center piece-left)
                                         (first (piece-lob piece-left))) #t)

(define (brick-rotation-past-wall? c b)
  (local [(define CW-B (brick-rotate-cw c b)) ; clockwise rotation of brick
          (define CCW-B (brick-rotate-ccw c b))] ; counter-clockwise rotation of brick
    (or (< (brick-x CW-B) 0)
        (> (brick-x CW-B) 9)
        (< (brick-x CCW-B) 0)
        (> (brick-x CCW-B) 9)
        (< (brick-y CW-B) 0) ; to check if it rotates past the bottom of the board
        (< (brick-y CCW-B) 0))))

;----------------------------------------------------------------------------------------------------
; rotation into pile of bricks at the bottom detection
;----------------------------------------------------------------------------------------------------
; rotation-into-pile? : World -> Boolean
; does a piece rotate into bricks in the pile at the bottom?
(check-expect (rotation-into-pile?
               (make-world (make-piece (list (make-brick 8 1 "purple") (make-brick 8 2 "purple")
                                             (make-brick 8 3 "purple") (make-brick 7 3 "purple"))
                                       (make-posn 8 2)) (list (make-brick 8 0 "cyan")
                                                              (make-brick 9 0 "cyan")
                                                              (make-brick 9 1 "cyan")
                                                              (make-brick 9 2 "cyan")) 0)) #t)
(check-expect (rotation-into-pile? world1) #f)

(define (rotation-into-pile? w)
  (piece-rotation-into-pile? (world-piece w) (world-lob w)))

; piece-rotation-into-pile? : Piece LOB -> Boolean
; does a piece rotate into bricks in the pile at the bottom?
(check-expect (piece-rotation-into-pile? (make-piece (list (make-brick 8 1 "purple")
                                                           (make-brick 8 2 "purple")
                                                           (make-brick 8 3 "purple")
                                                           (make-brick 7 3 "purple"))
                                                     (make-posn 8 2))
                                         (list (make-brick 8 0 "cyan")
                                               (make-brick 9 0 "cyan")
                                               (make-brick 9 1 "cyan")
                                               (make-brick 9 2 "cyan"))) #t)
(check-expect (piece-rotation-into-pile? o-piece-example '()) #f)

(define (piece-rotation-into-pile? p pile)
  (nelob-rotation-into-pile? (piece-lob p) (piece-center p) pile))

; nelob-rotation-into-pile? : NElob Posn LOB -> Boolean
; does a list of bricks rotate into bricks in the pile at the bottom?
(check-expect (nelob-rotation-into-pile? (list (make-brick 8 1 "purple")
                                               (make-brick 8 2 "purple")
                                               (make-brick 8 3 "purple")
                                               (make-brick 7 3 "purple"))
                                         (make-posn 8 2)  (list (make-brick 8 0 "cyan")
                                                                (make-brick 9 0 "cyan")
                                                                (make-brick 9 1 "cyan")
                                                                (make-brick 9 2 "cyan"))) #t)
(check-expect (nelob-rotation-into-pile? lob1 (piece-center i-piece-example) '()) #f)
                                                           
(define (nelob-rotation-into-pile? nelob c pile)
  (ormap (lambda (b) (brick-rotation-into-pile? b c pile)) nelob))

; brick-rotation-into-pile? : Brick Posn LOB -> Boolean
; does a brick rotate into bricks in the pile at the bottom?
(check-expect (brick-rotation-into-pile? (make-brick 8 1 "purple") (make-posn 8 2)
                                         (list (make-brick 8 0 "cyan")
                                               (make-brick 9 0 "cyan")
                                               (make-brick 9 1 "cyan")
                                               (make-brick 9 2 "cyan"))) #t)
(check-expect (brick-rotation-into-pile? brick1 (piece-center i-piece-example) '()) #f)

(define (brick-rotation-into-pile? b c lob)
  (local [(define CW-B (brick-rotate-cw c b)) ; clockwise rotation of brick
          (define CCW-B (brick-rotate-ccw c b)) ; counter-clockwise rotation of brick
          ; pile-overlap : Brick -> Boolean
          ; is a brick rotating into the pile?
          (define (pile-overlap b2)
            (or (and (= (brick-y CW-B) (brick-y b2))
                     (= (brick-x CW-B) (brick-x b2)))
                (and (= (brick-y CCW-B) (brick-y b2))
                     (= (brick-x CCW-B) (brick-x b2)))))]
    (ormap pile-overlap lob)))
  
;----------------------------------------------------------------------------------------------------
;; game-over functions
;----------------------------------------------------------------------------------------------------

;                                                                 
;                                             ;                   
;            ;                                ;                   
;            ;                                ;                   
;    ;;;   ;;;;;   ;;;   ;;;;         ;     ; ; ;;    ;;;   ; ;;  
;   ;   ;    ;    ;; ;;  ;; ;;        ;     ; ;;  ;  ;;  ;  ;;  ; 
;   ;        ;    ;   ;  ;   ;         ; ; ;  ;   ;  ;   ;; ;   ; 
;    ;;;     ;    ;   ;  ;   ;  ;;;;;; ; ; ;  ;   ;  ;;;;;; ;   ; 
;       ;    ;    ;   ;  ;   ;         ;; ;;  ;   ;  ;      ;   ; 
;   ;   ;    ;    ;; ;;  ;; ;;         ;; ;;  ;   ;  ;      ;   ; 
;    ;;;     ;;;   ;;;   ;;;;           ; ;   ;   ;   ;;;;  ;   ; 
;                        ;                                        
;                        ;                                        
;                        ;                                        

; game-over? : World -> Boolean
; are the pieces piling up above the top of the tetris board?
(check-expect (game-over? (make-world piece-above (list brick-above1) 0)) #t)
(check-expect (game-over? world1) #f)

(define (game-over? w)
  (lob-above? (world-lob w)))

; lob-above? : LOB -> Boolean
; are any of the bricks in the pile above the top of the board?
(check-expect (lob-above? lob-above) #t)
(check-expect (lob-above? lob1) #f)

(define (lob-above? lob)
  (ormap (lambda (b) (> (brick-y b) 19)) lob))

;----------------------------------------------------------------------------------------------------
; Spawning Random Pieces and Debris
;----------------------------------------------------------------------------------------------------

;                                                                                      
;                            ;                                                         
;                            ;                                                         
;                            ;                                                         
;    ;;;;  ;;;;   ; ;;    ;;;;   ;;;  ;;;;;;          ;;;   ;;;;   ;;;;  ;     ; ; ;;  
;    ;;  ;     ;  ;;  ;  ;; ;;  ;; ;; ;  ;  ;        ;   ;  ;; ;;      ; ;     ; ;;  ; 
;    ;         ;  ;   ;  ;   ;  ;   ; ;  ;  ;        ;      ;   ;      ;  ; ; ;  ;   ; 
;    ;      ;;;;  ;   ;  ;   ;  ;   ; ;  ;  ;         ;;;   ;   ;   ;;;;  ; ; ;  ;   ; 
;    ;     ;   ;  ;   ;  ;   ;  ;   ; ;  ;  ;            ;  ;   ;  ;   ;  ;; ;;  ;   ; 
;    ;     ;   ;  ;   ;  ;; ;;  ;; ;; ;  ;  ;        ;   ;  ;; ;;  ;   ;  ;; ;;  ;   ; 
;    ;      ;;;;  ;   ;   ;;;;   ;;;  ;  ;  ;         ;;;   ;;;;    ;;;;   ; ;   ;   ; 
;                                                           ;                          
;                                                           ;                          
;                                                           ;                          

;----------------------------------------------------------------------------------------------------
; Generating a Random Piece
;----------------------------------------------------------------------------------------------------

; new-piece : TypeNumber -> Piece
; generates the next piece of tetris when the last piece is below the board
(check-satisfied (new-piece 0) piece?)
(check-satisfied (new-piece 1) piece?)
(check-satisfied (new-piece 2) piece?)
(check-satisfied (new-piece 3) piece?)
(check-satisfied (new-piece 4) piece?)
(check-satisfied (new-piece 5) piece?)
(check-satisfied (new-piece 6) piece?)
(check-satisfied (new-piece 7) piece?)
(check-satisfied (new-piece 8) piece?)

(define (new-piece n)
  (cond [(= n 0) (make-o (+ (random 8) 1) 19)]
        [(= n 1) (make-i (+ (random 7) 1) 19)]
        [(= n 2) (make-l (+ (random 8) 1) 19)]
        [(= n 3) (make-j (+ (random 8) 1) 19)]
        [(= n 4) (make-t (+ (random 8) 1) 19)]
        [(= n 5) (make-z (+ (random 8) 1) 20)]
        [(= n 6) (make-s (+ (random 8) 1) 20)]
        [(= n 7) (make-magenta-piece (random 10) 19)]
        [(= n 8) (make-green-i (+ (random 6) 1) 19)]))  

;----------------------------------------------------------------------------------------------------
; random debris generation
;----------------------------------------------------------------------------------------------------
; random-debris : Rows Probability -> LOB
; generates a random pile of debris, given a number of rows and probability
(check-satisfied (random-debris 0 0) list?)
(check-satisfied (random-debris 10 45) list?)

(define (random-debris n p)
  (local [; probability-brick? : Brick -> Boolean
          ; is the randomly generated number less than the probability input?
          (define (probability-brick? _)
            (< (random 100) p))]
    (filter probability-brick? (build-list-debris n))))

; build-list-debris : Rows -> LOB
; generates debris pile as if probability was 100
(check-expect (build-list-debris 0) '())
(check-expect (build-list-debris 1) (list (make-brick 0 0 "grey") (make-brick 1 0 "grey")
                                          (make-brick 2 0 "grey") (make-brick 3 0 "grey")
                                          (make-brick 4 0 "grey") (make-brick 5 0 "grey")
                                          (make-brick 6 0 "grey") (make-brick 7 0 "grey")
                                          (make-brick 8 0 "grey") (make-brick 9 0 "grey")))

(define (build-list-debris n)
  (local [; make-debris : Natural -> Brick
          ; makes a brick that fills a position where there is debris on a tetris board.
          (define (make-debris x)
            (make-brick (modulo x 10) (quotient x 10) "grey"))]
    (build-list (* n 10) make-debris)))
