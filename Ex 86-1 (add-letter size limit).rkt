;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname |Ex 86-1 (add-letter size limit)|) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ())))
; note: there is something more elegant about this approach, but the other approach offers a better
; user experience. users do not expect the size of the letter to determine whether they can enter
; another letter or not. however, this would be a good way to handle line wrapping.

(require 2htdp/image)
(require 2htdp/universe)

; graphical constants
(define CURSOR (rectangle 1 20 "solid" "red"))
(define WIDTH 200)
(define HEIGHT 20)
(define MT (empty-scene WIDTH HEIGHT))
(define TEXT-SIZE 16)
(define TEXT-COLOR "black")

(define-struct editor [pre post])
; Editor = (make-editor String String)
; interpretation (make-editor s t) means the text in the editor is
; (string-append s t) with the cursor displayed between s and t
; examples:

(define hello-world (make-editor "hello" "world"))
(define hell-oworld (make-editor "hell" "oworld"))
(define hell-world (make-editor "hell" "world"))
(define hellow-orld (make-editor "hellow" "orld"))
(define h-elloworld (make-editor "h" "elloworld"))
(define -helloworld (make-editor "" "helloworld"))
(define helloworld- (make-editor "helloworld" ""))
(define helloworl- (make-editor "helloworl" ""))
(define helloworl (make-editor "helloworl" ""))
(define hello-orld (make-editor "hello" "orld"))
(define hellok-world (make-editor "hellok" "world"))

; WorldState -> WorldState
; run is my main function (not sure why they say to call it run)
; run takes in world states and spits out new world states, rendering them along the way

(define (run e)
  (big-bang e
   [on-key edit]
   [to-draw render]))

; Editor -> Image
; render takes in an editor worldstate and draws an image of it
; by placing the first string s, then placing CURSOR, then placing the second string t on the background MT
(define (render e)
  (overlay/align "left" "center" (draw-text e) MT))

; Editor -> Image
; draw-text is a function that renders all the text in the editor window
; having this as a separate function is helpful for limiting the width of text

(define (draw-text e)
  (beside (draw-string (editor-pre e)) CURSOR (draw-string (editor-post e))))


; Editor, KeyEvent -> Editor
; edit takes in an Editor e and a KeyEvent ke and produces another Editor.
; its task is to add a single-character KeyEvent ke to the end of the pre field of ed,
; unless ke denotes the backspace ("\b") key. In that case, it deletes the character immediately
; to the left of the cursor (if there are any).
; The function ignores the tab key ("\t") and the return key ("\r").

(define (edit e ke)
  (cond
    [(string=? ke "left") (move-left e)] 
    [(string=? ke "right") (move-right e)] 
    [(string=? ke "\b") (backspace e)]
    [(string=? ke "\t") e] ; is there a better way to exclude these?
    [(string=? ke "\r") e]
    [(= (string-length ke) 1) (limit-add-letter e ke)] ; added a limit-add-letter function here. it's nicer this way.
    [else e])) ; not a key event we care about, so return the same Editor

(check-expect (edit hello-world "\b") hell-world)
(check-expect (edit hello-world "left") hell-oworld)
(check-expect (edit -helloworld "left") -helloworld)
(check-expect (edit helloworld- "right") helloworld-)
(check-expect (edit hello-world "right") hellow-orld)
(check-expect (edit -helloworld "\b") -helloworld)
(check-expect (edit helloworld- "\b") helloworl-)
(check-expect (edit hello-world "blah") hello-world)
(check-expect (edit hello-world "\t") hello-world)
(check-expect (edit hello-world "\r") hello-world)
(check-expect (edit hello-world "k") hellok-world)
(check-expect (edit helloworl- "d") helloworld-)

; Editor -> Boolean
; A function got-space? that checks to see if the string overlay image is already wider
; than the WIDTH minus TEXT-SIZE

(define (got-space? e)
  (<= (image-width (draw-text e)) (- WIDTH TEXT-SIZE)))

(check-expect (got-space? (make-editor "short" "words")) true)
(check-expect (got-space? (make-editor "very long worlds" "that are ridiculously long")) false)


; String -> Image
; takes a string and renders an image in the appropriate font size and color
(define (draw-string t)
  (text t TEXT-SIZE TEXT-COLOR))

; Wishlist


; Editor -> Editor
; move-left moves the cursor left by moving the last letter of the first string (editor-pre e)
; to the first letter of the second string e-post
; unless you're all the way left already,
; that is, unless the pre string is "" but this will be dealt with by remove-last and last-letter
(define (move-left e)
  (make-editor (remove-last (editor-pre e)) (string-append (last-letter (editor-pre e)) (editor-post e))))

(check-expect (move-left hello-world) hell-oworld)
(check-expect (move-left -helloworld) -helloworld)

; Editor -> Editor
; move-right moves the cursor right by moving the first letter of the second string e-post
; to the last letter of the first string e-pre
; unless you're all the way left already
; that is, unless the post string is ""
(define (move-right e)
  (make-editor (string-append (editor-pre e) (first-letter (editor-post e))) (remove-first (editor-post e))))

(check-expect (move-right helloworld-) helloworld-)
(check-expect (move-right hello-world) hellow-orld)

; Editor -> Editor
; backspace removes the last letter of the first string and leaves the second string alone
; we can use the function remove last

(define (backspace e)
  (make-editor (remove-last (editor-pre e)) (editor-post e)))

(check-expect (backspace helloworld-) helloworl-)
(check-expect (backspace -helloworld) -helloworld)
(check-expect (backspace hello-world) hell-world)

; String -> Letter
; last-letter returns the last letter of a string

(define (last-letter s)
  (cond
    [(string=? s "") s]
    [else (substring s (- (string-length s) 1))]))


(check-expect (last-letter "helloworld") "d")
(check-expect (last-letter "hello") "o")
(check-expect (last-letter "") "")
(check-expect (last-letter "h") "h")

; String -> Letter
; first-letter returns the first letter of a string
(define (first-letter s)
  (cond
    [(string=? s "") s]
    [else (substring s 0 1)]))

; String -> String
; remove-last removes the last letter of a string
; if the string is "" it returns ""

(define (remove-last s)
  (cond
    [(string=? s "") s]
    [else (substring s 0 (- (string-length s) 1))]))

(check-expect (remove-last "") "")
(check-expect (remove-last "helloworld") "helloworl")

; String -> String
; remove-first removes the first letter of a string
; if the string is "" it returns ""

(define (remove-first s)
  (cond
    [(string=? s "") s]
    [else (substring s 1)]))

(check-expect (remove-first "") "")
(check-expect (remove-first "helloworld") "elloworld")
(check-expect (remove-first "first") "irst")

; Editor, Keyevent -> Editor
; add-letter adds the key event character to the current cursor position of editor e
; by adding it to (editor-pre e) and returning the modified Editor
; it also uses got-space? to check to make sure there is room for the letter
; if there is no room, it doesn't add anything

(define (add-letter e ke)
  (make-editor (string-append (editor-pre e) ke) (editor-post e)))

(check-expect (add-letter hello-world "k") hellok-world)
(check-expect (add-letter helloworl- "d") helloworld-)

; add a limit-add-letter function for add-letter that returns e if (render (add-letter e ke)) is too big and put that in main
; Editor, KeyEvent -> Editor

(define (limit-add-letter e ke)
  (cond
    [(> (image-width (render (add-letter e ke))) WIDTH) e]
    [else (add-letter e ke)]))


(run (make-editor "" ""))

