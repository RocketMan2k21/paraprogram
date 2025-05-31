; Лабораторна робота №5 - Спрощена версія
; Варіант 10: Розподіл Рейлі

; ==============================================
; БАЗА ФАКТІВ
; ==============================================

(deffacts input-data
    (data-value 77.04)
    (data-value 76.36)
    (data-value 77.30)
    (data-value 77.61)
    (data-value 76.67)
    (data-value 77.16)
    (data-value 77.45)
    (data-value 77.09)
    (data-value 76.28)
    (data-value 74.13)
    (data-value 73.74)
    (data-value 73.24)
    (data-value 72.80)
    (data-value 73.14)
    (data-value 73.14)
    (data-value 73.17)
    (data-value 74.21)
    (data-value 73.57)
    (data-value 73.44)
    (data-value 73.42)
)

(deffacts config
    (alphabet-size 6)
    (alphabet A B C D E F)
)

; ==============================================
; ШАБЛОНИ
; ==============================================

(deftemplate interval
    (slot index)
    (slot letter)
    (slot lower)
    (slot upper)
)

(deftemplate mapping
    (slot value)
    (slot letter)
)

(deftemplate transition
    (slot from)
    (slot to)
    (slot count)
)

; ==============================================
; ПРАВИЛА
; ==============================================

; Знаходження діапазону
(defrule find-range
    (declare (salience 100))
    (not (range-found))
    =>
    (bind ?values (create$))
    (do-for-all-facts ((?f data-value)) TRUE
        (bind ?values (insert$ ?values 1 (nth$ 1 ?f:implied)))
    )
    (bind ?min (nth$ 1 (sort > ?values)))
    (bind ?max (nth$ 1 (sort < ?values)))
    (assert (min-val ?min))
    (assert (max-val ?max))
    (assert (range-found))
    (printout t "=== РОЗПОДІЛ РЕЙЛІ ===" crlf)
    (printout t "Мін: " ?min ", Макс: " ?max crlf)
)

; Створення інтервалів
(defrule create-intervals
    (declare (salience 90))
    (range-found)
    (min-val ?min)
    (max-val ?max)
    (alphabet-size ?n)
    (alphabet $?letters)
    (not (intervals-ready))
    =>
    (bind ?range (- ?max ?min))
    (bind ?step (/ ?range ?n))
    
    (printout t "Створення інтервалів:" crlf)
    (loop-for-count (?i 1 ?n)
        (bind ?letter (nth$ ?i ?letters))
        (bind ?lower (+ ?min (* (- ?i 1) ?step)))
        (bind ?upper (+ ?min (* ?i ?step)))
        
        ; Розподіл Рейлі - модифікуємо межі
        (bind ?sigma 0.5)
        (bind ?p1 (/ ?i ?n))
        (bind ?p0 (/ (- ?i 1) ?n))
        
        ; Обчислення квантилів Рейлі
        (if (> ?p0 0) then
            (bind ?q0 (* ?sigma (sqrt (* -2 (log (- 1 ?p0))))))
        else
            (bind ?q0 0)
        )
        
        (if (< ?p1 1) then
            (bind ?q1 (* ?sigma (sqrt (* -2 (log (- 1 ?p1))))))
        else
            (bind ?q1 3.0)
        )
        
        ; Масштабування
        (bind ?norm-lower (+ ?min (* (/ ?q0 3.0) ?range)))
        (bind ?norm-upper (+ ?min (* (/ ?q1 3.0) ?range)))
        
        (assert (interval (index ?i) (letter ?letter) (lower ?norm-lower) (upper ?norm-upper)))
        (printout t ?i ": " ?letter " [" ?norm-lower " - " ?norm-upper "]" crlf)
    )
    (assert (intervals-ready))
)

; Відображення значень
(defrule map-values
    (declare (salience 80))
    (intervals-ready)
    (data-value ?val)
    (interval (letter ?letter) (lower ?low) (upper ?high))
    (test (and (>= ?val ?low) (< ?val ?high)))
    (not (mapping (value ?val)))
    =>
    (assert (mapping (value ?val) (letter ?letter)))
    (printout t ?val " -> " ?letter crlf)
)

; Обробка максимального значення
(defrule map-max
    (declare (salience 80))
    (intervals-ready)
    (max-val ?max)
    (data-value ?max)
    (alphabet-size ?n)
    (interval (index ?n) (letter ?letter))
    (not (mapping (value ?max)))
    =>
    (assert (mapping (value ?max) (letter ?letter)))
    (printout t ?max " -> " ?letter " (макс)" crlf)
)

; Створення послідовності
(defrule build-sequence
    (declare (salience 70))
    (intervals-ready)
    (not (sequence-built))
    =>
    (bind ?seq (create$))
    (bind ?values (create$ 77.04 76.36 77.30 77.61 76.67 77.16))
    
    (foreach ?val ?values
        (do-for-fact ((?m mapping)) (= ?m:value ?val)
            (bind ?seq (insert$ ?seq (+ (length$ ?seq) 1) ?m:letter))
        )
    )
    
    (assert (linguistic-seq ?seq))
    (assert (sequence-built))
    (printout t crlf "Лінгвістичний ряд: ")
    (foreach ?letter ?seq (printout t ?letter " "))
    (printout t crlf)
)

; Ініціалізація матриці
(defrule init-matrix
    (declare (salience 60))
    (sequence-built)
    (alphabet $?letters)
    (not (matrix-init))
    =>
    (foreach ?from ?letters
        (foreach ?to ?letters
            (assert (transition (from ?from) (to ?to) (count 0)))
        )
    )
    (assert (matrix-init))
)

; Підрахунок переходів
(defrule count-transitions
    (declare (salience 50))
    (linguistic-seq $?seq)
    (matrix-init)
    (not (counted))
    =>
    (bind ?len (length$ ?seq))
    (loop-for-count (?i 1 (- ?len 1))
        (bind ?from (nth$ ?i ?seq))
        (bind ?to (nth$ (+ ?i 1) ?seq))
        (do-for-fact ((?t transition)) (and (eq ?t:from ?from) (eq ?t:to ?to))
            (modify ?t (count (+ ?t:count 1)))
        )
    )
    (assert (counted))
)

; Виведення матриці
(defrule print-matrix
    (declare (salience 40))
    (counted)
    (alphabet $?letters)
    =>
    (printout t crlf "МАТРИЦЯ ПЕРЕХОДІВ:" crlf)
    (printout t "   ")
    (foreach ?l ?letters (printout t ?l " "))
    (printout t crlf)
    
    (foreach ?from ?letters
        (printout t ?from ": ")
        (foreach ?to ?letters
            (do-for-fact ((?t transition)) (and (eq ?t:from ?from) (eq ?t:to ?to))
                (printout t ?t:count " ")
            )
        )
        (printout t crlf)
    )
    (printout t crlf "Готово!" crlf)
)