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
  # Використовуємо правильний параметр для qrayleigh
  epsilon <- 1e-5
  probabilities <- seq(epsilon, 1 - epsilon, length.out = alphabet_size + 1)
  quantiles <- quantile(data, probs = seq(0, 1, length.out = alphabet_size + 1))

  
  # Нормалізуємо квантилі до діапазону даних
  quantiles <- min_val + (quantiles - min(quantiles)) * 
    (max_val - min_val) / (max(quantiles) - min(quantiles))
  
  # Перевіряємо на NA
  if(any(is.na(quantiles))) {
    stop("Помилка: Не вдалося створити інтервали")
  }
  
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