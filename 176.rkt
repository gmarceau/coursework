;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname |176|) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ())))
; A Matrix is one of: 
;  – (cons Row '())
;  – (cons Row Matrix)
; constraint all rows in matrix are of the same length 
 
; An Row is one of: 
;  – '() 
;  – (cons Number Row)

; A Column is a Row
; interpretation: a list of numbers in a column in a matrix.

(define SAMPLE-MATRIX
  (cons (cons 11 (cons 12 '())) (cons (cons 21 (cons 22 '())) '())))

(define row1 (cons 11 (cons 12 '())))
(define row2 (cons 21 (cons 22 '())))
(define mat1 (cons row1 (cons row2 '())))

; Matrix -> Matrix
; transpose the items on the given matrix along the diagonal 
 
(define wor1 (cons 11 (cons 21 '())))
(define wor2 (cons 12 (cons 22 '())))
(define tam1 (cons wor1 (cons wor2 '())))

(check-expect (transpose mat1) tam1)
 
(define (transpose lln)
  (cond
    [(empty? (first lln)) '()]
    [else (cons (first* lln) (transpose (rest* lln)))]))

; Matrix -> Column
; consumes a matrix and produces the first column as a list of numbers

(check-expect (first* '()) '())
(check-expect (first* mat1) wor1) 

(define (first* lln)
  (cond
    [(empty? lln) '()]
    [else (cons (first (first lln)) (first* (rest lln)))]))

; Matrix -> Matrix
; consumes a matrix and removes the first column.

(check-expect (rest* '()) '())
(check-expect (rest* mat1) (cons (cons 12 '()) (cons (cons 22 '()) '())))

(define (rest* lln)
  (cond
    [(empty? lln) '()]
    [else (cons (rest (first lln)) (rest* (rest lln)))]))


; Q. why can't we use the recipe? A. because first and rest are different?