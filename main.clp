; Лабораторна робота №5 - Мультипарадигменне програмування
; Варіант 10: Розподіл Рейлі
; Перетворення чисельного ряду до лінгвістичного ланцюжка

; ==============================================
; БАЗА ФАКТІВ
; ==============================================

; Вхідні дані з CSV (колонка Low)
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

; Параметри алфавіту
(deffacts alphabet-config
    (alphabet-size 6)
    (alphabet A B C D E F)
)

; Параметри розподілу Рейлі
(deffacts rayleigh-params
    (sigma 1.0)
)

; ==============================================
; ДОПОМІЖНІ СТРУКТУРИ
; ==============================================

; Шаблон для інтервалів
(deftemplate interval
    (slot index)
    (slot letter)
    (slot lower-bound)
    (slot upper-bound)
    (slot probability)
)

; Шаблон для відображення значень у літери
(deftemplate mapping
    (slot value)
    (slot letter)
)

; Шаблон для матриці переходів
(deftemplate transition
    (slot from)
    (slot to)
    (slot count)
)

; ==============================================
; ФУНКЦІЇ
; ==============================================

; Функція для знаходження мінімального значення
(deffunction find-min ()
    (bind ?min 999999)
    (do-for-all-facts ((?f data-value)) TRUE
        (bind ?val (fact-slot-value ?f implied))
        (if (< ?val ?min) then (bind ?min ?val))
    )
    (return ?min)
)

; Функція для знаходження максимального значення
(deffunction find-max ()
    (bind ?max -999999)
    (do-for-all-facts ((?f data-value)) TRUE
        (bind ?val (fact-slot-value ?f implied))
        (if (> ?val ?max) then (bind ?max ?val))
    )
    (return ?max)
)

; Функція для обчислення CDF Рейлі
(deffunction rayleigh-cdf (?x ?sigma)
    (if (<= ?x 0) then
        (return 0.0)
    else
        (return (- 1.0 (exp (/ (* ?x ?x -1) (* 2 ?sigma ?sigma)))))
    )
)

; ==============================================
; ПРАВИЛА ОБРОБКИ
; ==============================================

; Правило 1: Знаходження мін/макс значень
(defrule find-min-max
    (declare (salience 100))
    (not (min-value ?))
    (not (max-value ?))
    =>
    (printout t "Знаходження мінімального та максимального значень..." crlf)
    (bind ?min (find-min))
    (bind ?max (find-max))
    (assert (min-value ?min))
    (assert (max-value ?max))
    (assert (range (- ?max ?min)))
    (printout t "Мінімальне значення: " ?min crlf)
    (printout t "Максимальне значення: " ?max crlf)
    (printout t "Діапазон: " (- ?max ?min) crlf)
)

; Правило 2: Підготовка розподілу Рейлі
(defrule prepare-rayleigh
    (declare (salience 90))
    (min-value ?)
    (max-value ?)
    (not (rayleigh-ready))
    =>
    (printout t "Підготовка розподілу Рейлі..." crlf)
    (assert (rayleigh-ready))
)

; Правило 3: Створення інтервалів
(defrule create-intervals
    (declare (salience 80))
    (rayleigh-ready)
    (alphabet-size ?n)
    (alphabet $?letters)
    (min-value ?min)
    (max-value ?max)
    (not (intervals-created))
    =>
    (printout t "Створення інтервалів для розподілу Рейлі..." crlf)
    (bind ?sigma 0.8)
    (bind ?norm-range 3.0)
    
    (printout t "Діапазон значень: [" ?min ", " ?max "]" crlf)
    
    (loop-for-count (?i 1 ?n)
        (bind ?letter (nth$ ?i ?letters))
        
        ; Рівні ймовірності для кожного інтервалу
        (bind ?p-lower (/ (- ?i 1) ?n))
        (bind ?p-upper (/ ?i ?n))
        
        ; Зворотна функція розподілу Рейлі
        (if (= ?p-lower 0) then
            (bind ?x-lower 0)
        else
            (bind ?x-lower (* ?sigma (sqrt (* -2 (log (- 1 ?p-lower))))))
        )
        
        (if (= ?p-upper 1) then
            (bind ?x-upper ?norm-range)
        else
            (bind ?x-upper (* ?sigma (sqrt (* -2 (log (- 1 ?p-upper))))))
        )
        
        ; Масштабування до реального діапазону
        (bind ?real-lower (+ ?min (* (/ ?x-lower ?norm-range) (- ?max ?min))))
        (bind ?real-upper (+ ?min (* (/ ?x-upper ?norm-range) (- ?max ?min))))
        
        (assert (interval 
            (index ?i) 
            (letter ?letter) 
            (lower-bound ?real-lower) 
            (upper-bound ?real-upper)
            (probability (- ?p-upper ?p-lower))
        ))
        
        (printout t "Інтервал " ?i ": " ?letter " [" 
                 (format nil "%.3f" ?real-lower) ", " 
                 (format nil "%.3f" ?real-upper) "] p=" 
                 (format nil "%.3f" (- ?p-upper ?p-lower)) crlf)
    )
    (assert (intervals-created))
)

; Правило 4: Відображення значень у літери
(defrule map-values-to-letters
    (declare (salience 70))
    (intervals-created)
    (data-value ?v)
    (interval (letter ?letter) (lower-bound ?lb) (upper-bound ?ub))
    (test (and (>= ?v ?lb) (< ?v ?ub)))
    (not (mapping (value ?v)))
    =>
    (assert (mapping (value ?v) (letter ?letter)))
    (printout t "Значення " ?v " -> " ?letter crlf)
)

; Правило 5: Обробка максимального значення
(defrule map-max-value
    (declare (salience 70))
    (intervals-created)
    (max-value ?max)
    (data-value ?max)
    (alphabet-size ?n)
    (interval (index ?n) (letter ?letter))
    (not (mapping (value ?max)))
    =>
    (assert (mapping (value ?max) (letter ?letter)))
    (printout t "Максимальне значення " ?max " -> " ?letter crlf)
)

; Правило 6: Створення лінгвістичного ряду
(defrule create-linguistic-sequence
    (declare (salience 60))
    (intervals-created)
    (not (linguistic-sequence $?))
    =>
    (bind ?sequence (create$))
    
    ; Збираємо всі значення в порядку їх появи
    (do-for-all-facts ((?d data-value)) TRUE
        (bind ?val (fact-slot-value ?d implied))
        (do-for-fact ((?m mapping)) (= ?m:value ?val)
            (bind ?sequence (insert$ ?sequence (+ (length$ ?sequence) 1) ?m:letter))
        )
    )
    
    (assert (linguistic-sequence ?sequence))
    (printout t crlf "Лінгвістичний ряд: ")
    (foreach ?letter ?sequence (printout t ?letter " "))
    (printout t crlf)
)

; Правило 7: Ініціалізація матриці переходів
(defrule init-transition-matrix
    (declare (salience 50))
    (linguistic-sequence $?seq)
    (alphabet $?letters)
    (not (matrix-initialized))
    =>
    (printout t "Ініціалізація матриці переходів..." crlf)
    (foreach ?from ?letters
        (foreach ?to ?letters
            (assert (transition (from ?from) (to ?to) (count 0)))
        )
    )
    (assert (matrix-initialized))
)

; Правило 8: Підрахунок переходів
(defrule count-transitions
    (declare (salience 40))
    (linguistic-sequence $?seq)
    (matrix-initialized)
    (not (transitions-counted))
    =>
    (printout t "Підрахунок переходів..." crlf)
    (bind ?len (length$ ?seq))
    (if (> ?len 1) then
        (loop-for-count (?i 1 (- ?len 1))
            (bind ?from (nth$ ?i ?seq))
            (bind ?to (nth$ (+ ?i 1) ?seq))
            (do-for-fact ((?t transition))
                (and (eq ?t:from ?from) (eq ?t:to ?to))
                (modify ?t (count (+ ?t:count 1)))
            )
            (printout t "Перехід " ?from " -> " ?to crlf)
        )
    )
    (assert (transitions-counted))
)

; Правило 9: Виведення матриці переходів
(defrule print-transition-matrix
    (declare (salience 30))
    (transitions-counted)
    (alphabet $?letters)
    (not (matrix-printed))
    =>
    (printout t crlf "=== МАТРИЦЯ ПЕРЕХОДІВ ===" crlf)
    (printout t "     ")
    (foreach ?letter ?letters (printout t ?letter "   "))
    (printout t crlf)
    
    (foreach ?from ?letters
        (printout t ?from "  ")
        (foreach ?to ?letters
            (do-for-fact ((?t transition))
                (and (eq ?t:from ?from) (eq ?t:to ?to))
                (printout t ?t:count "   ")
            )
        )
        (printout t crlf)
    )
    (assert (matrix-printed))
    (printout t crlf "Обробку завершено!" crlf)
)

; ==============================================
; ЗАПИТИ
; ==============================================

; Основне правило запуску
(defrule start-processing
    (declare (salience 1000))
    =>
    (printout t "=== Лабораторна робота №5 ===" crlf)
    (printout t "Варіант 10: Розподіл Рейлі" crlf)
    (printout t "Обробка даних з колонки Low" crlf)
    (printout t "===============================" crlf)
)

; Запити для отримання результатів
(defquery get-linguistic-sequence
    (linguistic-sequence $?seq)
)

(defquery get-transition-matrix
    (transition (from ?f) (to ?t) (count ?c))
)

; ==============================================
; ФУНКЦІЇ ТЕСТУВАННЯ
; ==============================================

(deffunction test-with-custom-data (?values)
    "Тестування з власними даними"
    (reset)
    (foreach ?val ?values
        (assert (data-value ?val))
    )
    (run)
)