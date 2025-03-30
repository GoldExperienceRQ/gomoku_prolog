
computer_move(Algorithm, Board, Depth, Player, BestMove):-
    (Algorithm = minimax -> minimax(Board, Depth, Player, BestMove);
    Algorithm = alphabeta -> alphabeta_search(Board, Depth, Player, BestMove)).

minimax(Board, Depth, Player, BestMove) :-
    findall(Move, adjacent_valid_move(Board, Move), Moves),
    sort(Moves, UniqueMoves),
    (Player = 'x' ->   CurrentBestScore = -1000000;
     Player = 'o' ->   CurrentBestScore = 1000000),
 	evaluate_and_choose(Board, UniqueMoves, Depth, Player, nil, CurrentBestScore, BestMove), !.


adjacent_valid_move(Board, (R, C)) :-
    board_size(Board, Size),
    Max is Size - 1,
    between(0, Max, R),
    between(0, Max, C),
    nth0(R, Board, Row),
    nth0(C, Row, empty),
    adjacent_to_played(Board, R, C).


adjacent_to_played(Board, R, C) :-
    member((DR, DC), [(-1,-1),(-1,0),(-1,1),
                        ( 0,-1),        (0,1),
                        ( 1,-1),( 1,0),(1,1)]),
    R1 is R + DR,
    C1 is C + DC,
    within_board(Board, R1, C1),
    nth0(R1, Board, AdjRow),
    nth0(C1, AdjRow, V),
    member(V, ['x', 'o']).

% Check that the cell (R, C) is within the board.
within_board(Board, R, C) :-
    board_size(Board, Size),
    R >= 0, R < Size,
    C >= 0, C < Size.

% Determine board size (assumes square board).
board_size(Board, Size) :-
    length(Board, Size).


evaluate_and_choose(_Board, [], _Depth, _Player, CurrentBestMove, _CurrentBestScore,  CurrentBestMove).
evaluate_and_choose(Board, [Move|Rest], Depth, Player, CurrentBestMove, CurrentBestScore,  BestMove) :-
    make_move(Board, Move, Player, NewBoard),
    (   (   game_over(NewBoard, Winner), Winner = Player) -> BestMove = Move;

    D1 is Depth - 1,
    minimax_score(NewBoard, D1, Player, Score),
    (   Player = 'x' ->  ( Score > CurrentBestScore ->  NewBestMove = Move, NewBestScore = Score;
                           NewBestMove = CurrentBestMove, NewBestScore = CurrentBestScore);
    	Player = 'o' ->   (   Score < CurrentBestScore ->  NewBestMove = Move, NewBestScore = Score;
                           NewBestMove = CurrentBestMove, NewBestScore = CurrentBestScore )
    ),
     evaluate_and_choose(Board, Rest, Depth, Player, NewBestMove, NewBestScore, BestMove)).



minimax_score(Board, 0, Player, Score) :-
    evaluate(Board, Player, Score).

minimax_score(Board, Depth, Player, Score) :-
    findall(Move, adjacent_valid_move(Board, Move), Moves),
    sort(Moves, UniqueMoves),
    switch_player(Player, NextPlayer),
    evaluate_scores(Board, UniqueMoves, Depth, NextPlayer, Scores),
    (   NextPlayer = 'x' -> max_list(Scores, Score)
    ;   NextPlayer = 'o' -> min_list(Scores, Score)
    ).


evaluate_scores(_, [], _Depth, _Player, []).
evaluate_scores(Board, [Move|Rest], Depth, Player, [Score|Scores]) :-
    make_move(Board, Move, Player, NewBoard),
    (   (   game_over(NewBoard, Winner), Winner = Player) -> (   Player = 'x' ->   Score = 500000; Player = 'o' ->  Score = -500000),
        Scores = [Score];
    	D1 is Depth - 1,
    	minimax_score(NewBoard, D1, Player, Score),
    	evaluate_scores(Board, Rest, Depth, Player, Scores)
    ).

% Switch between players.
switch_player('x', 'o').
switch_player('o', 'x').

% --- Board Manipulation Predicates ---

% Make a move on the board.
make_move(Board, (Row, Col), Player, NewBoard) :-
    nth0(Row, Board, OldRow),
    replace(OldRow, Col, Player, NewRow),
    replace(Board, Row, NewRow, NewBoard).

% Replace the element at index I in a list.
replace([_|T], 0, X, [X|T]).
replace([H|T], I, X, [H|R]) :-
    I > 0,
    I1 is I - 1,
    replace(T, I1, X, R).

evaluate(Board, Player, Score) :-
    all_lines(Board, Lines),
    ( Player = 'x' ->  evaluate_lines(Lines, 'x', false, ScoreX), evaluate_lines(Lines, 'o', true, ScoreO);
    Player = 'o' ->  evaluate_lines(Lines, 'x', true, ScoreX), evaluate_lines(Lines, 'o', false, ScoreO)),
    Score is ScoreX - ScoreO.

evaluate_lines([], _Player, _Passive, 0).
evaluate_lines([Line|Rest], Player, Passive, TotalScore) :-
    line_score(Line, Player, Passive, Score1),
    evaluate_lines(Rest, Player, Passive, ScoreRest),
    TotalScore is Score1 + ScoreRest.


opponent('x', 'o').
opponent('o', 'x').


pattern(_, 0, []).
pattern(Player, N, [Player|Rest]) :-
    N > 0,
    N1 is N - 1,
    pattern(Player, N1, Rest).

count_open_patterns(Line, Pattern, CountOne, CountBoth) :-
    count_open_patterns_helper(Line, Pattern, 0, 0, CountOne, CountBoth).

count_open_patterns_helper(Line, Pattern, AccOne, AccBoth, CountOne, CountBoth) :-
    (   % Спроба розбити рядок так, щоб Rest починалася з Pattern
        append(Before, Rest, Line),
        prefix(Pattern, Rest),
        append(Pattern, After, Rest),
        Pattern = [P|_],
        (   length(Pattern, 5)
        ->  IncOne = 1, IncBoth = 0
        ;   % Якщо довжина патерна менша за 5, перевіряємо, що входження є точним:
            (   (Before == [] ; (last(Before, X), X \== P)),
                (After == [] ; (After = [Y|_], Y \== P))
            ->  (   both_open(Before, After)
                ->  IncOne = 0, IncBoth = 1
                ;   one_open(Before, After)
                ->  IncOne = 1, IncBoth = 0
                ;   IncOne = 0, IncBoth = 0
                )
            ;   IncOne = 0, IncBoth = 0
            )
        )
    ->  (   % Пропускаємо перший елемент Rest, щоб уникнути перекриття
            Rest = [_|Tail]
        ->  NewAccOne is AccOne + IncOne,
            NewAccBoth is AccBoth + IncBoth,
            count_open_patterns_helper(Tail, Pattern, NewAccOne, NewAccBoth, CountOne, CountBoth)
        ;   CountOne is AccOne + IncOne,
            CountBoth is AccBoth + IncBoth
        )
    ;   (   Line = [_|Tail]
        ->  count_open_patterns_helper(Tail, Pattern, AccOne, AccBoth, CountOne, CountBoth)
        ;   ( CountOne = AccOne, CountBoth = AccBoth )
        )
    ).

prefix([], _).
prefix([X|Xs], [X|Ys]) :-
    prefix(Xs, Ys).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Допоміжні предикати для перевірки відкритості входження
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% both_open(Before, After)
both_open(Before, After) :-
    Before \= [], After \= [],
    last(Before, B), B == empty,
    After = [A|_], A == empty.

% one_open(Before, After)
one_open(Before, After) :-
    (After = [A|_], A == empty)
    ;
    (last(Before, B), B == empty).


line_score(Line, Player, Passive, Score) :-
    % Генеруємо патерни для 2, 3 та 4 в ряд
    pattern(Player, 2, P2),
    pattern(Player, 3, P3),
    pattern(Player, 4, P4),

    opponent(Player, Opponent),
    pattern(Opponent, 3, O3),
    pattern(Opponent, 4, O4),

    % Підраховуємо кількість випадків для кожного патерна
    count_open_patterns(Line, P2, CountOne2, CountBoth2),
    count_open_patterns(Line, P3, CountOne3, CountBoth3),
    count_open_patterns(Line, P4, CountOne4, CountBoth4),

    %Патерни для опонента
    count_open_patterns(Line, O3, _CountOneOpp3, CountBothOpp3),
    count_open_patterns(Line, O4, CountOneOpp4, CountBothOpp4),


    CurrentScore is CountOne2*10 + CountBoth2*20 +
             CountOne3*100 + CountBoth3*200 +
             CountOne4*1000 + CountBoth4*2000,
    (Passive = false ->
    (
    CountOneOpp4 > 0  -> Score is CurrentScore - 100000;
    CountBothOpp3 > 0, ( CountOne4 = 0; CountBoth4 = 0 ) -> Score is CurrentScore - 10000;
    	Score is CurrentScore
    );
    Score = CurrentScore
    ).



% all_lines(+Board, -Lines)
all_lines(Board, Lines) :-
    Rows = Board,
    transpose(Board, Columns),
    diagonals(Board, Diags),
    anti_diagonals(Board, AntiDiags),
    append([Rows, Columns, Diags, AntiDiags], Lines).

% transpose(+Matrix, -Transposed)
transpose([], []).
transpose([[]|_], []).
transpose(Matrix, [Row|Rows]) :-
    maplist(list_first, Matrix, Row),
    maplist(list_rest, Matrix, RestMatrix),
    transpose(RestMatrix, Rows).

list_first([X|_], X).
list_rest([_|Xs], Xs).

% diagonals(+Board, -Diagonals)
diagonals(Board, Diagonals) :-
    board_size(Board, Size),
    Low is -(Size - 1),
    High is Size - 1,
    findall(Diag,
            ( between(Low, High, D),
              diagonal(Board, D, Diag)
            ),
            Diagonals).

diagonal(Board, D, Diag) :-
    board_size(Board, Size),
    Max is Size - 1,
    findall(Element,
            ( between(0, Max, I),
              J is I - D,
              J >= 0, J < Size,
              nth0(I, Board, Row),
              nth0(J, Row, Element)
            ),
            Diag),
    Diag \= [].

% anti_diagonals(+Board, -AntiDiagonals)
anti_diagonals(Board, AntiDiagonals) :-
    board_size(Board, Size),
    Low is 0,
    High is 2*(Size - 1),
    findall(Diag,
            ( between(Low, High, Sum),
              anti_diagonal(Board, Sum, Diag)
            ),
            AntiDiagonals).

anti_diagonal(Board, Sum, Diag) :-
    board_size(Board, Size),
    Max is Size - 1,
    findall(Element,
            ( between(0, Max, I),
              J is Sum - I,
              J >= 0, J < Size,
              nth0(I, Board, Row),
              nth0(J, Row, Element)
            ),
            Diag),
    Diag \= [].





game_over(Board, Winner) :-
    ( winning(Board, 'x') ->   Winner = 'x'
    ; winning(Board, 'o') ->   Winner = 'o'
    ).


winning(Board, Player) :-
    pattern(Player, 5, Pattern),
    all_lines(Board, Lines),
    member(Line, Lines),
    count_open_patterns(Line, Pattern, CountOne, CountBoth),
    (   CountOne > 0; CountBoth > 0).








