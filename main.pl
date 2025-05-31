:- use_module(library(csv)).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(clpfd)).

% === ЗАДАЧА ===
% 1. Зчитати числовий ряд (Low) з CSV
% 2. Розбити на інтервали за розподілом Релея
% 3. Перетворити на лінгвістичний ряд
% 4. Побудувати матрицю переходів між літерами

% === НАСТРОЙКИ ===
alphabet(['A','B','C','D','E']).  % Змінюй алфавіт тут
csv_file('data.csv').

% === ГОЛОВНИЙ ВИКЛИК ===
go :-
    statistics(walltime, [Start|_]),
    csv_file(File),
    read_low_column(File, RawList),
    sort(RawList, Sorted),
    write('Сортування завершено\n'),
    compute_reyleigh_thresholds(Sorted, Thresholds),
    write('Пороги за Релеєм: '), writeln(Thresholds),
    to_linguistic(Sorted, Thresholds, Linguistic),
    write('Лінгвістичний ряд: '), writeln(Linguistic),
    build_transition_matrix(Linguistic, Matrix),
    writeln('Матриця переходів:'),
    print_matrix(Matrix),
    statistics(walltime, [End|_]),
    Time is (End - Start) / 1000,
    format('Час виконання: ~2f секунд~n', [Time]).

% === Зчитування колонки Low ===
read_low_column(File, Values) :-
    csv_read_file(File, [Header|Rows], [functor(row), separator(0',)]),
    arg_pos('Low', Header, Pos),
    maplist(arg(Pos), Rows, Values).

safe_probability(I, N, P) :-
    TmpP is I / N,
    ( TmpP >= 0.999 -> P = 0.999 ; P = TmpP ).

arg_pos(Name, Row, Pos) :-
    Row =.. [_|Cols],
    nth1(Pos, Cols, Name).

% === Побудова порогів за Релеєм ===
compute_reyleigh_thresholds(Values, Thresholds) :-
    alphabet(Alphabet),
    length(Alphabet, N),
    sigma(Values, Sigma),
    numlist(1, N, Indexes),
    maplist(rayleigh_threshold(Sigma, N), Indexes, Thresholds).

sigma(Values, Sigma) :-
    sum_list(Values, Sum),
    length(Values, Len),
    Mean is Sum / Len,
    Sigma is Mean / sqrt(pi / 2).

rayleigh_threshold(Sigma, N, I, T) :-
   safe_probability(I, N, P),
   T is Sigma * sqrt(-2 * log(1 - P)).

% === Перетворення на лінгвістичний ряд ===
to_linguistic([], _, []).
to_linguistic([V|Vs], Thresholds, [Sym|Rest]) :-
    alphabet(Alphabet),
    assign_symbol(V, Thresholds, Alphabet, Sym),
    to_linguistic(Vs, Thresholds, Rest).

assign_symbol(Value, [T|_], [Sym|_], Sym) :-
    Value =< T, !.
assign_symbol(Value, [_|Ts], [_|Ss], Sym) :-
    assign_symbol(Value, Ts, Ss, Sym).
assign_symbol(_, [], [Sym], Sym). % якщо більше останнього порогу

% === ВИПРАВЛЕНА побудова матриці переходів ===
build_transition_matrix(Sequence, Matrix) :-
    alphabet(Alphabet),
    length(Alphabet, N),
    % Створюємо порожню матрицю N x N
    create_empty_matrix(N, EmptyMatrix),
    % Збираємо всі переходи
    collect_transitions(Sequence, Transitions),
    % Заповнюємо матрицю
    fill_matrix_with_transitions(Transitions, Alphabet, EmptyMatrix, Matrix).

% Створення порожньої матриці N x N
create_empty_matrix(N, Matrix) :-
    length(Matrix, N),
    maplist(create_zero_row(N), Matrix).

create_zero_row(N, Row) :-
    length(Row, N),
    maplist(=(0), Row).

% Збір всіх переходів із послідовності
collect_transitions([], []).
collect_transitions([_], []).
collect_transitions([A,B|Rest], [A-B|Transitions]) :-
    collect_transitions([B|Rest], Transitions).

% Заповнення матриці переходами
fill_matrix_with_transitions([], _, Matrix, Matrix).
fill_matrix_with_transitions([From-To|Transitions], Alphabet, CurrentMatrix, FinalMatrix) :-
    nth0(I, Alphabet, From),
    nth0(J, Alphabet, To),
    increment_matrix_element(CurrentMatrix, I, J, UpdatedMatrix),
    fill_matrix_with_transitions(Transitions, Alphabet, UpdatedMatrix, FinalMatrix).

% Збільшення елемента матриці на 1
increment_matrix_element(Matrix, I, J, UpdatedMatrix) :-
    nth0(I, Matrix, Row),
    nth0(J, Row, OldValue),
    NewValue is OldValue + 1,
    replace_nth0(J, Row, NewValue, NewRow),
    replace_nth0(I, Matrix, NewRow, UpdatedMatrix).

% Заміна елемента за індексом
replace_nth0(0, [_|T], X, [X|T]).
replace_nth0(N, [H|T], X, [H|R]) :-
    N > 0,
    N1 is N - 1,
    replace_nth0(N1, T, X, R).

% === Вивід матриці ===
print_matrix(Matrix) :-
    alphabet(Alphabet),
    write('\t'), print_header(Alphabet), nl,
    print_rows(Alphabet, Matrix).

print_header([]).
print_header([H|T]) :- 
    write(H), write('\t'), 
    print_header(T).

print_rows([], []).
print_rows([Label|Labels], [Row|Rows]) :-
    write(Label), write('\t'),
    print_list(Row), nl,
    print_rows(Labels, Rows).

print_list([]).
print_list([H|T]) :- 
    write(H), write('\t'), 
    print_list(T).

% === ДОДАТКОВІ ДОПОМІЖНІ ПРЕДИКАТИ ===

% Показати статистику переходів
show_transition_stats(Linguistic) :-
    collect_transitions(Linguistic, Transitions),
    length(Transitions, TotalTransitions),
    writeln('=== СТАТИСТИКА ПЕРЕХОДІВ ==='),
    format('Загальна кількість переходів: ~w~n', [TotalTransitions]),
    group_transitions(Transitions, GroupedTransitions),
    print_transition_counts(GroupedTransitions).

% Групування переходів
group_transitions([], []).
group_transitions([T|Ts], [T-Count|Grouped]) :-
    include(=(T), [T|Ts], Same),
    length(Same, Count),
    exclude(=(T), Ts, Different),
    group_transitions(Different, Grouped).

% Вивід кількості переходів
print_transition_counts([]).
print_transition_counts([From-To-Count|Rest]) :-
    format('~w -> ~w: ~w~n', [From, To, Count]),
    print_transition_counts(Rest).

% Розширений виклик з статистикою
go_with_stats :-
    statistics(walltime, [Start|_]),
    go,
    csv_file(File),
    read_low_column(File, RawList),
    sort(RawList, Sorted),
    compute_reyleigh_thresholds(Sorted, Thresholds),
    to_linguistic(Sorted, Thresholds, Linguistic),
    show_transition_stats(Linguistic),
    statistics(walltime, [End|_]),
    Time is (End - Start) / 1000,
    format('Загальний час виконання: ~2f секунд~n', [Time]).