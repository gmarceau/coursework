;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname |Ex 103|) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ())))
(require 2htdp/image)
(require 2htdp/universe)

; physical constants

;world
(define WIDTH 200)
(define HEIGHT 200)
(define MIDDLE (/ WIDTH 2))
(define LAND-HEIGHT 20)
(define SKY (rectangle WIDTH HEIGHT "solid" "blue"))
(define LAND (rectangle WIDTH LAND-HEIGHT "solid" "green"))
(define BACKGROUND (place-image LAND (/ WIDTH 2) (- HEIGHT (/ LAND-HEIGHT 2)) SKY))

;misc game aspects

(define WIN-TEXT "GAME OVER: YOU WIN!")
(define LOSE-TEXT "GAME OVER: YOU LOSE!")
(define FONT-SIZE 14)
(define FONT-COLOR "white")

(define R 10) ;The global hit radius of objects... how close objects can get measured from their "centers" or their point if one dimensional.

;stuff

(define TANK (rectangle 30 20 "solid" "gray"))
(define TANK-Y (- HEIGHT (image-height LAND)))
(define TANK-SPEED 3)

(define missile (rectangle 2 6 "solid" "orange"))
(define missile-SPEED 10)
(define missile-STARTY (- TANK-Y (/ (image-height missile) 2)))

(define UFO-HEIGHT 7)
(define UFO-WIDTH 30)
(define UFO (overlay (circle UFO-HEIGHT "solid" "red") (rectangle UFO-WIDTH 4 "solid" "red")))
(define UFO-SPEED 2)
(define UFORANDOM 5)

; Data Definitions

; TankPosition is a Number in (0,WIDTH)
; interpretation: the position of the tank on the x-axis
; examples:

(define TANK-MIDDLE MIDDLE)
(define TANK-LEFT 0)
(define TANK-RIGHT WIDTH)

; Velocity is a Number.
; interpretation: the speed and direction of the tank (positive is to the right, negative to the left)

; TankPosition is an Integer in (0, WIDTH)
; interpretation: the position of the tank along the x axis.

; Tank is a structure (make-tank TankPosition Velocity)

(define-struct tank (x vel))

; examples of Tank:
(define tank-l-l (make-tank 0 (* TANK-SPEED -1)))
(define tank-l-r (make-tank 0 TANK-SPEED))
(define tank-r-r (make-tank WIDTH TANK-SPEED))
(define tank-m-r (make-tank MIDDLE TANK-SPEED))
(define tank-m-l (make-tank MIDDLE (* TANK-SPEED -1)))
(define tank-m-0 (make-tank MIDDLE 0))

; UFO is a Position (make-posn x y) 
; interpretation: the x,y coordinates of a UFO
; examples of UFO: 

(define ufostart (make-posn MIDDLE 0))
(define ufodown1 (make-posn MIDDLE UFO-SPEED))
(define ufohalfway (make-posn MIDDLE (/ HEIGHT 2)))
(define ufoplanet (make-posn MIDDLE (- HEIGHT LAND-HEIGHT)))

; Location is one of:
; – Posn
; – Number
; interpretation Posn are positions on the Cartesian plane,
; Numbers are positions on either the x- or the y-axis.
; this definition helps me think about the function in-reach?


(define-struct sigs.v2 [ufo tank missile])

; SIGS.v2 (short for version 2) 
; is (make-sigs UFO Tank MissileOrNot)
; interpretation represents the state of the space invader game 
 
; A MissileOrNot is one of: 
; – #false
; – Posn
; interpretation #false means the missile hasn't been fired yet;
; Posn says the missile has been fired and is at the specified location. 


; FUNCTIONS

; SIGS -> SIGS
; main function calls big-bang ontick, todraw, and onkey 
; to draw the world, handle key events, and move my objects on clock ticks

(define (main s)
  (big-bang s
            [to-draw render]
            [on-tick si-move]
            [on-key si-control]
            [stop-when si-game-over? si-render-final]))


; SIGS.v2 -> Image 
; renders the given game state and added it to BACKGROUND
(define (si-render.v2 s)
  (tank-render (fired-tank s)
               (ufo-render (fired-ufo s)
                            (missile-render.v2 (fired-missile s)
                                               BACKGROUND))))

; SIGS -> SIGS
; tock moves Tank, UFO, and Missle in the ways that they are pre-determined to on each clock tick.
; this is just a composing function, so I'm putting all the tests in the sub functions.

(define (si-move s)
  (cond
    [(fired? s)(tank-move (missle-move (ufo-move s)))]
    [(aim? s)(tank-move (ufo-move s))]))

; SIGS -> SIGS
; si-control moves the tank left and right when user hits the respective arrow keys, and launches a missle when spacebar is pressed.

(check-expect (si-control aimstart " ") firedstart) ; make sure space launches the missle
(check-expect (tank-vel (aim-tank (si-control aimstart "right"))) TANK-SPEED) ; is this a valid way to write tests?
(check-expect (tank-vel (aim-tank (si-control aimstart "left"))) (* TANK-SPEED -1))

(define (si-control s ke)
  (cond
    [(string=? ke " ")(fire-if-aim s)] ; fires the missle
    [(string=? ke "left")(update-tank-vel s (* TANK-SPEED -1))] ;
    [(string=? ke "right")(update-tank-vel s TANK-SPEED)]
    [else s]))

; SIGS -> Boolean
; si-game-over? returns true when the game is over, whether the player won or lost,
; that is, either when the missle hits the UFO or when the UFO hits ("lands on") the planet.

(check-expect (si-game-over? aimstart) false)
(check-expect (si-game-over? aimufodown1) false)
(check-expect (si-game-over? aimok) false)
(check-expect (si-game-over? aimlose) true)
(check-expect (si-game-over? firedstart) false)
(check-expect (si-game-over? firedmiss) false)
(check-expect (si-game-over? firedclosemiss) false)
(check-expect (si-game-over? firedclosehit) true)
(check-expect (si-game-over? fireddirecthit) true)

(define (si-game-over? s)
  (or (game-over-lose? s) (game-over-win? s)))


; SIGS -> SIGS
; If the SIGS s is an Aim, fire-if-aim will fire the missle,
; by changing the Aim to a Fired with all the same values for Tank (fired-tank) and UFO (fired-ufo)
; and with a Missle (fired-missle) with the same x value as the Tank (tank-x (aim-tank))
; and the y value MISSLE-STARTY
; If the SIGS s is a Fired, it does nothing.

(check-expect (fire-if-aim firedstart) firedstart) ; make sure it does nothing if already fired.
(check-expect (fire-if-aim firedmiss) firedmiss)
(check-expect (fire-if-aim aimstart) firedstart) ; make sure it changes the state
(check-expect (posn-x (fired-missle (fire-if-aim aimstart))) (posn-x (aim-tank aimstart))) ; make sure the x value is the same as the tank
(check-expect (posn-y (fired-missle (fire-if-aim aimstart))) MISSLE-STARTY) ; make sure the y value is MISSLE-STARTY

(define (fire-if-aim s)
  (cond
    [(aim? s) (make-fired (aim-tank s) (aim-ufo s) (make-posn (tank-x (aim-tank s)) MISSLE-STARTY))] ;makes a "fired" where everything is the same except adding a missle with the x value of the tank and the y value MISSLE-STARTY
    [else s])) ;if s is not an Aim, do nothing.
              
; SIGS -> SIGS
; tank-move moves the tank on a clock tick, depending on direction and TANK-SPEED.

(define (tank-move s)
  (cond
    [(fired? s)(make-fired (tank-step (fired-tank s)) (fired-ufo s) (fired-missle s))]
    [(aim? s)(make-aim (tank-step (aim-tank s)) (aim-ufo s))])) ;having to do this conditional all the time seems like a real weakness of the language or the approach.

; Tank -> Tank
; tank-step moves the tank t (tank-vel t)

(check-expect (tank-step (make-tank 100 -2)) (make-tank 98 -2))
(check-expect (tank-step (make-tank 100 2)) (make-tank 102 2))
(check-expect (tank-step (make-tank WIDTH 2)) (make-tank WIDTH 2))
(check-expect (tank-step (make-tank 0 -2)) (make-tank 0 -2))

(define (tank-step t)
  (make-tank (x-limit (+ (tank-x t) (tank-vel t))) (tank-vel t)))

; SIGS, Number -> SIGS
; update-tank-vel updates the velocity of the SIGS s to the Number v

(check-expect (update-tank-vel aimstart TANK-SPEED) (make-aim tank-m-r ufostart))
(check-expect (update-tank-vel aimstart (* TANK-SPEED -1)) (make-aim tank-m-l ufostart))
(check-expect (update-tank-vel (make-aim tank-m-l ufostart) TANK-SPEED) (make-aim tank-m-r ufostart))
; I should add tests in here for fired states

(define (update-tank-vel s v)
  (cond
    [(aim? s) (make-aim (make-tank (tank-x (aim-tank s)) v) (aim-ufo s))] ; leaves everything the same except the tank velocity which it replaces with v
    [(fired? s) (make-fired (make-tank (tank-x (fired-tank s)) v) (fired-ufo s) (fired-missle s))])) ; ditto here


; Number -> Number
; x-limit keeps the x coordinate of objects inside (0, WIDTH) when they move.

(check-expect (x-limit -5) 0)
(check-expect (x-limit 0) 0)
(check-expect (x-limit 1) 1)
(check-expect (x-limit WIDTH) WIDTH)
(check-expect (x-limit (+ WIDTH 5)) WIDTH)
(check-expect (x-limit (- WIDTH 1)) (- WIDTH 1))

(define (x-limit x)
  (cond
    [(< x 0) 0]
    [(> x WIDTH) WIDTH]
    [else x]))


; SIGS -> SIGS
; ufo-move moves the tank on a clock tick, down the screen and randomly to the left and right.
; this another composing function so I'm going to put tests in sub-functions.
; also, I don't know how to write tests for a function that involves a random

(define (ufo-move s)
  (ufo-random (ufo-down s)))

; SIGS -> SIGS
; ufo-random moves the ufo in SIGS s in "small random jumps to the left or right"
; note that it doesn't call the random function.

(define (ufo-random s)
  (cond
    [(fired? s) (make-fired (fired-tank s) (ufo-jump (fired-ufo s)) (fired-missle s))] ;how would I make a move-thing function that would work for tank and ufo and MISSLE? 
    [(aim? s) (make-aim (aim-tank s) (ufo-jump (aim-ufo s)))]))

; Position, Number -> Position
; xmove moves a Posn pos (e.g. a UFO or a Tank) left or right by adding a positive or negative number to (posn-x pos)
; xmove uses limitx to keep x inside the range (0, WIDTH)
; I could use this for my tank moving function at some point.

(check-expect (xmove (make-posn 100 100) 10) (make-posn 110 100))
(check-expect (xmove (make-posn 100 100) -10) (make-posn 90 100))
(check-expect (xmove (make-posn 0 100) -10) (make-posn 0 100))
(check-expect (xmove (make-posn WIDTH 100) 10) (make-posn WIDTH 100))

(define (xmove pos n)
  (make-posn (x-limit (+ n (posn-x pos))) (posn-y pos)))

; Posn -> Posn
; ufo-jump moves a Posn (UFO) u randomly left or right by adding a number in [-UFORANDOM,UFORANDOM] to it.

(define (ufo-jump u)
  (xmove u (- (random (+ (* UFORANDOM 2) 1)) UFORANDOM))) ;this looks complicated, but it's just to take the range of random positive integers and center it around zero.

; SIGS -> SIGS
; ufo-down moves the ufo in SIGS s down the screen at a regular pace at a speed from constants.

(check-expect (ufo-down aimstart) aimufodown1)

(define (ufo-down s)
  (cond
    [(fired? s)(make-fired (fired-tank s) (ufo-step (fired-ufo s)) (fired-missle s))]
    [(aim? s)(make-aim (aim-tank s) (ufo-step (aim-ufo s)))]))

; UFO -> UFO
; ufo-step moves a UFO u down the screen by adding the constant UFO-SPEED to its y coordinate
; (posn-y u)

(check-expect (ufo-step (make-posn 100 100)) (make-posn 100 (+ 100 UFO-SPEED)))

(define (ufo-step u)
  (make-posn (posn-x u) (+ (posn-y u) UFO-SPEED)))

; SIGS -> SIGS
; missle-move moves the missle on a clock tick, down the screen and randomly to the left and right.
; if the missle moves off the screen missle-move returns an Aim state.

(check-expect (missle-move firedstart) firedupone)
(check-expect (missle-move firedend) aimhalfway)
  

(define (missle-move s)
  (cond
    [(missle-off-screen? s)(make-aim (fired-tank s) (fired-ufo s))] ;for the missle off screen condition
    [(fired? s)(make-fired (fired-tank s) (fired-ufo s) (missle-step (fired-missle s)))]
    [else s])) ;only fired states have a missle to move

; Fired -> Boolean
; finding its a lot harder to write tests for these than it is to write the function.

(define (missle-off-screen? s)
  (< (posn-y (fired-missle s)) 0))
  
; Position -> Position
; missle-step moves a missle m up the screen by the constant MISSLE-SPEED by subtracting
; from its y value (posn-y m) and leaving its x value (posn-x m) untouched.

(check-expect (missle-step (make-posn 100 100)) (make-posn 100 (- 100 MISSLE-SPEED)))

(define (missle-step m)
  (make-posn (posn-x m) (- (posn-y m) MISSLE-SPEED)))

; SIGS -> Image
; si-render-final renders the final screen of the game when the game ends.
; it should say "game over: you win" if the missle hits the UFO.
; or "game over: you lose" if the missle hits the planet.

(define (si-render-final s)
  (cond
    [(game-over-lose? s)(text-render LOSE-TEXT (render s))]
    [(game-over-win? s)(text-render WIN-TEXT (render s))]))

; String, Image -> Image
; text-render overlays the text for a given string s in constant font and color
; on a given image i.

(define (text-render s i)
  (overlay (text s FONT-SIZE FONT-COLOR) i))

; SIGS -> Boolean
; game-over-lose? tells me if the player has lost, that is, if the UFO has hit the planet for a given SIGS s.

(check-expect (game-over-lose? fireddirecthit) false)
(check-expect (game-over-lose? firedclosehit) false)
(check-expect (game-over-lose? aimstart) false)
(check-expect (game-over-lose? aimok) false)
(check-expect (game-over-lose? aimlose) true)
(check-expect (game-over-lose? firedstart) false)
(check-expect (game-over-lose? firedmiss) false)
               
(define (game-over-lose? s)
  (cond
    [(fired? s)(ufo-landed? (fired-ufo s))]
    [(aim? s)(ufo-landed? (aim-ufo s))]))

; UFO -> Boolean
; ufo-landed? tells me if a given UFO u has landed, given some constants about where land is.

(check-expect (ufo-landed? (aim-ufo aimlose)) true)
(check-expect (ufo-landed? (aim-ufo aimstart)) false)
(check-expect (ufo-landed? (aim-ufo aimok)) false)

(define (ufo-landed? u)
  (in-reach? (- (- HEIGHT LAND-HEIGHT) (posn-y u))))

; SIGS -> Boolean
; game-over-win? tells me if the player has won, that is if the Missle has hit the UFO for a given SIGS s.

(check-expect (game-over-win? fireddirecthit) true)
(check-expect (game-over-win? aimstart) false)
(check-expect (game-over-win? aimok) false)
(check-expect (game-over-win? aimlose) false)
(check-expect (game-over-win? firedstart) false)
(check-expect (game-over-win? firedmiss) false)
(check-expect (game-over-win? firedclosemiss) false)
(check-expect (game-over-win? firedclosehit) true)
               
(define (game-over-win? s)
  (cond
    [(fired? s)(in-reach? (distance (fired-missile s) (fired-ufo s)))]
    [else false]))

; Position, Position -> Position (where posn-x and posn-y are both greater than 0)
; distance determines the distance between two positions, p1 and p2 and returns a special Position.
; in which both posn-x and posn-y are greater than zero (using absolute value).

(check-expect (distance (make-posn 5 0) (make-posn 0 0)) (make-posn 5 0))
(check-expect (distance (make-posn 0 5) (make-posn 0 0)) (make-posn 0 5))
(check-expect (distance (make-posn 3 4) (make-posn 0 0)) (make-posn 3 4))
(check-expect (distance (make-posn -5 0) (make-posn 0 0)) (make-posn 5 0))
(check-expect (distance (make-posn 10 15) (make-posn 10 10)) (make-posn 0 5))
(check-expect (distance (make-posn -5 -5) (make-posn 0 0)) (make-posn 5 5))

(define (distance loc1 loc2)
  (make-posn (abs (- (posn-x loc1) (posn-x loc2))) (abs (- (posn-y loc1) (posn-y loc2)))))

; Location -> Boolean
; determines whether a location's distance to the origin is strictly less than some constant R

(check-expect (in-reach? (* 2 R)) false)
(check-expect (in-reach? R) false)
(check-expect (in-reach? (- R 1)) true)
(check-expect (in-reach? 0) true)

(check-expect (in-reach? (make-posn R R)) false)
(check-expect (in-reach? (make-posn (/ R 2) (/ R 2))) true)
(check-expect (in-reach? (make-posn 0 R)) false)
(check-expect (in-reach? (make-posn 0 0)) true)
                                                                   
(define (in-reach? loc)
  (cond
    [(posn? loc)(< (sqrt (+ (sqr (posn-x loc)) (sqr (posn-y loc)))) R)]
    [(number? loc)(< loc R)]))

; Tank, Image -> Image
; tank-render draws a Tank t over an image i.

(define (tank-render t i)
  (place-image TANK (tank-x t) TANK-Y i))

; UFO, Image -> Image
; ufo-render draws a UFO u over an image i.

(define (ufo-render u i)
  (place-image UFO (posn-x u) (posn-y u) i))

; missile, Image -> Image
; missile-render draws a missile m over an image i

(define (missile-render m i)
  (place-image missile (posn-x m) (posn-y m) i))

(main sigsstart)