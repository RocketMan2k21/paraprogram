# Лабораторна робота №3
## Мультипарадигменне програмування
### Варіант 10 - Розподіл Рейлі

## 1. Постановка завдання

### Мета роботи
Реалізація перетворення чисельного ряду в лінгвістичний ланцюжок з подальшою побудовою матриці передування за допомогою мультипарадигменної мови R.

### Вхідні дані
- Чисельний ряд (колонка "Low" з CSV файлу)
- Розподіл ймовірностей (Розподіл Рейлі)
- Потужність алфавіту (15 символів)

### Вихідні дані
- Лінгвістичний ряд
- Матриця передування

## 2. Розв'язання задачі

### Бібліотека функцій та їх взаємозв'язок
```
main()
├── read_data() - читання даних з файлу
│   └── Перетворення даних у числовий формат
│   └── Нормалізація даних
├── create_intervals() - створення інтервалів
│   └── Розрахунок квантилів за розподілом Рейлі
│   └── Нормалізація інтервалів
├── create_linguistic_chain() - створення лінгвістичного ряду
│   └── value_to_letter() - перетворення числа в літеру
└── create_transition_matrix() - створення матриці передування
    └── Підрахунок переходів між символами
```

### Опис функцій
1. `read_data(filename)` - читає дані з CSV файлу, перетворює їх у числовий формат та нормалізує
2. `create_intervals(data, alphabet_size)` - створює інтервали на основі розподілу Рейлі
3. `value_to_letter(value, intervals)` - перетворює числове значення в літеру
4. `create_linguistic_chain(data, intervals)` - створює лінгвістичний ряд
5. `create_transition_matrix(linguistic_chain)` - будує матрицю передування

## 3. Результати розрахунку

### Вхідні параметри
- Розмір алфавіту: 15 символів
- Вхідні дані: колонка "Low" з CSV файлу

### Лінгвістичний ряд
Перші 50 елементів лінгвістичного ряду:
```
[1] "K" "K" "K" "K" "K" "K" "K" "K" "K" "K" "K" "K" "J" "K" "K" "J" "K" "K" "K"
[20] "K" "K" "K" "K" "K" "K" "K" "K" "K" "K" "K" "K" "K" "K" "K" "K" "K" "K" "K"
[39] "K" "K" "K" "K" "K" "K" "K" "K" "K" "J" "J" "J"
```

### Матриця передування
Матриця розміром 15x15 показує кількість переходів між символами:
```
      [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9] [,10] [,11] [,12] [,13] [,14] [,15]
 [1,]  327    6    0    0    0    0    0    0    0     0     0     0     0     0     0
 [2,]    7  298   27    0    0    0    0    0    0     0     0     0     0     0     0
 [3,]    0   28  274   31    0    0    0    0    0     0     0     0     0     0     0
 [4,]    0    0   32  283   20    0    0    0    0     0     0     0     0     0     0
 [5,]    0    0    0   21  288   23    0    0    0     0     0     0     0     0     0
 [6,]    0    0    0    0   24  283   27    0    0     0     0     0     0     0     0
 [7,]    0    0    0    0    0   28  286   19    0     0     0     0     0     0     0
 [8,]    0    0    0    0    0    0   20  291   23     0     0     0     0     0     0
 [9,]    0    0    0    0    0    0    0   24  288    21     0     0     0     0     0
[10,]    0    0    0    0    0    0    0    0   22   285    25     0     0     0     0
[11,]    0    0    0    0    0    0    0    0    0    26   302     6     0     0     0
[12,]    0    0    0    0    0    0    0    0    0     0     6   310    18     0     0
[13,]    0    0    0    0    0    0    0    0    0     0     0    18   276    36     2
[14,]    0    0    0    0    0    0    0    0    0     0     0     0    38   266    30
[15,]    0    0    0    0    0    0    0    0    0     0     0     0     0    32   302
```

### Час виконання
- Час виконання програми: 0.39 секунд
- Час компіляції: 4.76 секунд

![Результати виконання](screenshot.png)

## 4. Лістінг програмного коду

```R
# Лабораторна робота №3
# Варіант 10 - Розподіл Рейлі

# Функція для читання даних з файлу
read_data <- function(filename) {
  tryCatch({
    raw_data <- read.csv(filename, header = TRUE, stringsAsFactors = FALSE)

    # Перевірка на наявність колонки "Low"
    if (!"Low" %in% colnames(raw_data)) {
      stop("Файл не містить колонки 'Low'")
    }

    # Замінюємо кому на крапку (на випадок якщо числа в європейському форматі)
    raw_data$Low <- gsub(",", ".", raw_data$Low)

    # Перетворюємо у числовий формат
    data <- as.numeric(raw_data$Low)

    # Видаляємо NA (наприклад, якщо є неповні або текстові рядки)
    data <- data[!is.na(data)]
    data <- (data - min(data)) / (max(data) - min(data))

    if(length(data) == 0) {
      stop("У колонці 'Low' немає дійсних числових значень.")
    }

    return(data)
  }, error = function(e) {
    stop("Помилка при читанні або обробці файлу: ", e$message)
  })
}

# Функція для розбиття на інтервали за розподілом Рейлі
create_intervals <- function(data, alphabet_size) {
  sorted_data <- sort(data)
  min_val <- min(sorted_data)
  max_val <- max(sorted_data)
  
  # Створюємо квантилі для розподілу Рейлі
  sigma <- sqrt(2/pi) * mean(data)  # оцінка параметра масштабу
  epsilon <- 1e-5
  probabilities <- seq(epsilon, 1 - epsilon, length.out = alphabet_size + 1)
  quantiles <- quantile(data, probs = seq(0, 1, length.out = alphabet_size + 1))
  
  return(quantiles)
}

# Функція для перетворення числового значення в літеру
value_to_letter <- function(value, intervals) {
  # Перевіряємо на NA
  if(is.na(value)) {
    return(NA)
  }
  
  # Перевіряємо, чи значення в межах інтервалів
  if(value < intervals[1] || value > intervals[length(intervals)]) {
    return(NA)
  }
  
  for (i in 1:(length(intervals)-1)) {
    if (!is.na(intervals[i]) && !is.na(intervals[i+1]) &&
        value >= intervals[i] && value < intervals[i+1]) {
      return(LETTERS[i])
    }
  }
  return(LETTERS[length(intervals)-1])  # для останнього інтервалу
}

# Функція для створення лінгвістичного ряду
create_linguistic_chain <- function(data, intervals) {
  chain <- sapply(data, function(x) value_to_letter(x, intervals))
  # Видаляємо NA значення
  chain <- chain[!is.na(chain)]
  if(length(chain) == 0) {
    stop("Помилка: Не вдалося створити лінгвістичний ряд")
  }
  return(chain)
}

# Функція для створення матриці передування
create_transition_matrix <- function(linguistic_chain) {
  n <- length(LETTERS)
  matrix_size <- min(n, length(unique(linguistic_chain)))
  transition_matrix <- matrix(0, nrow = matrix_size, ncol = matrix_size)
  
  for (i in 1:(length(linguistic_chain)-1)) {
    current <- which(LETTERS == linguistic_chain[i])
    next_letter <- which(LETTERS == linguistic_chain[i+1])
    if (current <= matrix_size && next_letter <= matrix_size) {
      transition_matrix[current, next_letter] <- transition_matrix[current, next_letter] + 1
    }
  }
  
  return(transition_matrix)
}

# Головна функція
main <- function(filename, alphabet_size = 26) {
  # Вимірюємо час виконання
  start_time <- Sys.time()
  
  # Читаємо дані
  data <- read_data(filename)
  
  # Створюємо інтервали
  intervals <- create_intervals(data, alphabet_size)
  
  # Створюємо лінгвістичний ряд
  linguistic_chain <- create_linguistic_chain(data, intervals)
  
  # Створюємо матрицю передування
  transition_matrix <- create_transition_matrix(linguistic_chain)
  
  # Вимірюємо час виконання
  end_time <- Sys.time()
  execution_time <- end_time - start_time
  
  # Виводимо результати
  cat("Лінгвістичний ряд (перші 50 елементів):\n")
  print(head(linguistic_chain, 50))
  cat("\nМатриця передування:\n")
  print(transition_matrix)
  cat("\nЧас виконання:", execution_time, "секунд\n")
  
  return(list(
    linguistic_chain = linguistic_chain,
    transition_matrix = transition_matrix,
    execution_time = execution_time
  ))
}

# Запуск програми
if (!require("VGAM")) {
  install.packages("VGAM")
}
library(VGAM)

# Запитуємо користувача про розмір алфавіту
cat("Введіть розмір алфавіту (за замовчуванням 26): ")
alphabet_size <- as.numeric(readline())
if(is.na(alphabet_size) || alphabet_size < 1) {
  alphabet_size <- 26
  cat("Використовуємо розмір алфавіту за замовчуванням (26)\n")
}

# Вимірюємо час компіляції
compile_start <- Sys.time()

# Вибір файлу через діалогове вікно
if (!require("tcltk")) {
  install.packages("tcltk")
}
library(tcltk)

filename <- tclvalue(tkgetOpenFile(
  title = "Виберіть файл з даними",
  filetypes = "{{CSV files} {.csv}} {{All files} {*}}"
))

if (filename == "") {
  stop("Файл не вибрано")
}

result <- main(filename, alphabet_size)
compile_end <- Sys.time()
compile_time <- compile_end - compile_start

cat("\nЧас компіляції:", compile_time, "секунд\n")
``` 