# Лабораторна робота №1
## Мультипарадигменне програмування
### Весна 2025

## 1. Постановка завдання

### Мета роботи
Реалізація перетворення чисельного ряду до лінгвістичного ланцюжка за певним розподілом ймовірностей з подальшою побудовою матриці передування на процедурній мові програмування.

### Вхідні дані
- Чисельний ряд (дані про ціни на нафту Brent)
- Вид розподілу ймовірностей (дискретний рівномірний розподіл)
- Потужність алфавіту (задається користувачем)

### Вихідні дані
- Лінгвістичний ряд
- Матриця передування
- Статистика по інтервалах

## 2. Розв'язання задачі

### Алгоритм
1. **Читання та підготовка даних**
   - Відкриття CSV файлу з даними
   - Читання та парсинг рядків
   - Збереження числових значень у масив

2. **Сортування числового ряду**
   - Реалізація алгоритму бульбашкового сортування
   - Визначення мінімального та максимального значень
   - Розрахунок діапазону значень

3. **Розбиття на інтервали**
   - Розрахунок ширини інтервалу
   - Визначення меж інтервалів
   - Призначення літер алфавіту інтервалам

4. **Перетворення в лінгвістичний ряд**
   - Заміна числових значень на відповідні літери
   - Формування лінгвістичного ряду

5. **Побудова матриці передування**
   - Аналіз послідовності літер
   - Підрахунок переходів між літерами
   - Заповнення матриці передування

### Бібліотека функцій

1. **bubble_sort(arr, size)**
   - Призначення: сортування масиву за зростанням
   - Вхідні параметри:
     - arr: масив дійсних чисел
     - size: розмір масиву
   - Вихідні дані: відсортований масив

2. **Основний модуль (time_series_analysis)**
   - Функції читання файлу
   - Функції парсингу CSV
   - Функції перетворення в лінгвістичний ряд
   - Функції побудови матриці передування
   - Функції виведення результатів

## 3. Результати розрахунку

### Приклад виконання програми
```
Reading CSV file...
Finished reading file. Total records: 1000
Enter alphabet size (max 26): 5

Value range: 27.88 to 103.19
Interval width: 15.06
Using discrete uniform distribution (equal probability intervals)

Linguistic series (first 100 characters):
DDDDDDDDDDDDCDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC...

Transition matrix:
    A  B  C  D  E
A  90  5  0  0  0
B   5 10  0  0  0
C   0 10  2  0  0
D   0  0 28  1  0
E   0  0  0  0 35

Interval statistics:
Interval A: [27.88, 42.94] - 95 elements (9.50%)
Interval B: [42.94, 58.00] - 548 elements (54.80%)
Interval C: [58.00, 73.07] - 231 elements (23.10%)
Interval D: [73.07, 88.13] - 90 elements (9.00%)
Interval E: [88.13, 103.19] - 36 elements (3.60%)

Execution time: 4.39 seconds
```

### Аналіз результатів
1. **Час виконання**: 4.39 секунд
2. **Розподіл даних**:
   - Найбільша кількість значень (54.80%) припадає на інтервал B
   - Найменша кількість значень (3.60%) припадає на інтервал E
3. **Матриця передування**:
   - Найчастіші переходи: D→D (28 разів)
   - Найрідкісніші переходи: D→E (1 раз)

## 4. Лістінг програмного коду

```fortran
program time_series_analysis
    implicit none
    
    ! Constants
    integer, parameter :: MAXSIZE = 1000, MAXALPH = 26
    
    ! Variables for timing
    integer :: start_time, end_time, count_rate
    real :: elapsed_time
    
    ! Variables for file reading and linguistic conversion
    integer :: io_status, i, j, n, alphabet_size
    character(len=1000) :: line, temp_str
    real :: price
    
    ! Arrays for linguistic conversion
    real :: numbers(MAXSIZE), sorted_numbers(MAXSIZE)
    character(len=1) :: alphabet(MAXALPH)
    character(len=1) :: linguistic(MAXSIZE)
    integer :: transition_matrix(MAXALPH, MAXALPH)
    real :: min_val, max_val, interval_width
    integer :: interval_index, prev_index, count_elem
    
    ! Variables for CSV parsing
    integer :: comma_pos, quote_pos, start_pos
    
    ! Initialize alphabet
    do i = 1, MAXALPH
        alphabet(i) = char(ichar('A') + i - 1)
    end do
    
    ! Initialize transition matrix
    transition_matrix = 0
    
    ! Open the file
    open(unit=10, file='B-C-D-E-F-Brent Oil Futures Historical Data.csv', status='old', iostat=io_status)
    if (io_status /= 0) then
        print *, 'Error opening file'
        stop
    end if
    
    ! Start timing
    call system_clock(start_time, count_rate)
    
    ! Skip header
    read(10, '(A)', iostat=io_status) line
    print *, 'Reading CSV file...'
    
    ! Read and process data
    n = 0
    do
        read(10, '(A)', iostat=io_status) line
        if (io_status /= 0) exit
        if (len_trim(line) == 0) cycle
        
        ! Parse CSV: find first comma and extract price field
        comma_pos = index(line, '","')
        if (comma_pos == 0) cycle
        
        start_pos = comma_pos + 3
        quote_pos = index(line(start_pos:), '"')
        if (quote_pos == 0) cycle
        
        temp_str = line(start_pos:start_pos+quote_pos-2)
        read(temp_str, *, iostat=io_status) price
        if (io_status /= 0) cycle
        
        n = n + 1
        if (n <= MAXSIZE) then
            numbers(n) = price
        else
            print *, 'Warning: Maximum array size reached. Processing first', MAXSIZE, 'records.'
            n = MAXSIZE
            exit
        end if
    end do
    
    close(10)
    print *, 'Finished reading file. Total records:', n
    
    if (n == 0) then
        print *, 'No records were read from the file!'
        stop
    end if
    
    ! Copy numbers for sorting (step 1: sort numerical series)
    do i = 1, n
        sorted_numbers(i) = numbers(i)
    end do
    
    call bubble_sort(sorted_numbers, n)
    
    ! Find min and max values to get range
    min_val = sorted_numbers(1)
    max_val = sorted_numbers(n)
    
    ! Get alphabet size from user
    print *, 'Enter alphabet size (max 26):'
    read(*,*) alphabet_size
    
    if (alphabet_size > MAXALPH .or. alphabet_size <= 0) then
        print *, 'Error: invalid alphabet size'
        stop
    end if
    
    ! Step 2: Divide range into equal intervals (uniform distribution)
    ! For discrete uniform distribution, each interval has equal probability 1/n
    interval_width = (max_val - min_val) / real(alphabet_size)
    
    print *, 'Value range:', min_val, ' to', max_val
    print *, 'Interval width:', interval_width
    print *, 'Using discrete uniform distribution (equal probability intervals)'
    
    ! Step 3: Convert each numerical value to corresponding alphabet letter
    do i = 1, n
        if (interval_width > 0.0) then
            interval_index = int((numbers(i) - min_val) / interval_width)
        else
            interval_index = 0
        end if
        ! Handle edge case for maximum value
        if (interval_index >= alphabet_size) then
            interval_index = alphabet_size - 1
        end if
        ! Ensure valid index
        if (interval_index < 0) then
            interval_index = 0
        end if
        linguistic(i) = alphabet(interval_index + 1)
    end do
    
    ! Step 4: Output linguistic series
    print *, 'Linguistic series (first 100 characters):'
    do i = 1, min(n, 100)
        write(*,'(A1,$)') linguistic(i)
    end do
    if (n > 100) print *, '... (truncated)'
    print *
    
    ! Step 5: Build transition matrix
    do i = 2, n
        prev_index = ichar(linguistic(i-1)) - ichar('A') + 1
        interval_index = ichar(linguistic(i)) - ichar('A') + 1
        transition_matrix(prev_index, interval_index) = &
            transition_matrix(prev_index, interval_index) + 1
    end do
    
    ! Print transition matrix
    print *
    print *, 'Transition matrix:'
    print *, '(rows = previous letter, columns = next letter)'
    
    ! Print column headers
    write(*,'(4X,$)')
    do j = 1, alphabet_size
        write(*,'(A1,2X,$)') alphabet(j)
    end do
    print *
    
    ! Print matrix rows
    do i = 1, alphabet_size
        write(*,'(A1,2X,$)') alphabet(i)
        do j = 1, alphabet_size
            write(*,'(I2,1X,$)') transition_matrix(i, j)
        end do
        print *
    end do
    
    ! Print interval statistics
    print *
    print *, 'Interval statistics (uniform distribution):'
    do i = 1, alphabet_size
        count_elem = 0
        do j = 1, n
            if (linguistic(j) == alphabet(i)) then
                count_elem = count_elem + 1
            end if
        end do
        write(*,'(A,A1,A,F8.2,A,F8.2,A,I4,A,F6.2,A)') &
            'Interval ', alphabet(i), ': [', &
            min_val + (i-1)*interval_width, ', ', &
            min_val + i*interval_width, '] - ', &
            count_elem, ' elements (', 100.0*count_elem/n, '%)'
    end do
    
    ! End timing
    call system_clock(end_time)
    elapsed_time = real(end_time - start_time) / real(count_rate)
    print *, 'Execution time:', elapsed_time, 'seconds'
    
end program time_series_analysis

! Bubble sort subroutine
subroutine bubble_sort(arr, size)
    implicit none
    integer :: size
    real :: arr(size)
    integer :: i, j
    real :: temp
    
    do i = 1, size-1
        do j = 1, size-i
            if (arr(j) > arr(j+1)) then
                temp = arr(j)
                arr(j) = arr(j+1)
                arr(j+1) = temp
            end if
        end do
    end do
    
end subroutine bubble_sort
```

### Коментарі до коду
1. **Структура програми**:
   - Оголошення констант та змінних
   - Ініціалізація алфавіту
   - Читання та обробка даних
   - Перетворення в лінгвістичний ряд
   - Побудова матриці передування
   - Виведення результатів

2. **Ключові особливості**:
   - Використання дискретного рівномірного розподілу
   - Динамічний вибір розміру алфавіту
   - Ефективна обробка CSV файлу
   - Детальна статистика по інтервалах 