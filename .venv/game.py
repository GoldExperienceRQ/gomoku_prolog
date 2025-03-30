import tkinter as tk
from tkinter import messagebox
from pyswip import Prolog


# Set up the main application window
root = tk.Tk()
root.title("Gomoku Game")





# Initialize Prolog and load the Gomoku AI logi
prolog = Prolog()
prolog.consult("gomoku.pl")
# board = [["empty" for _ in range(10)] for _ in range(10)]
# board[0][0] = 'x'
# query = f"minimax({board}, 1, o, Move)"
# res = list(prolog.query(query))
# print(res)

# "minimax([[x, x, 'empty', empty, empty], [empty, empty, empty, empty, empty],[empty, empty, empty, empty, empty],[empty, empty, empty, empty, empty],[empty, empty, empty, empty, empty]], 1, o, Move)"

# Global variables for game state
board = []      # 2D list to represent the board (0 = empty, 1 = human, 2 = computer)
buttons = []    # 2D list of Button widgets corresponding to board cells
board_size_var = tk.StringVar()   # Tkinter variable for board size selection
difficulty_var = tk.StringVar()   # Tkinter variable for difficulty selection
algorithm_var = tk.StringVar()


# Set default options
board_size_var.set("10")   # default board size 10x10
difficulty_var.set("1")    # default difficulty level 1 (easy)
algorithm_var.set("minimax")
def start_game():
   """Start a new Gomoku game with the selected board size and difficulty."""
   global board, buttons  # we will modify these globals
   size = int(board_size_var.get())
   depth = int(difficulty_var.get())
   algo = algorithm_var.get()
   # Initialize an empty board (matrix of 0's)
   board = [["empty" for _ in range(size)] for _ in range(size)]
   # Reset the GUI board: destroy any existing buttons from a previous game
   for row_widgets in buttons:
       for btn in row_widgets:
           btn.destroy()
   buttons = []
   # Create a new grid of buttons for the board
   for r in range(size):
       row_buttons = []
       for c in range(size):
           # Create a button for each cell. Initially empty text.
           btn = tk.Button(board_frame, text="", width=2, height=1, font=("Arial", 14),
                            command=lambda rr=r, cc=c: player_move(rr, cc))
           btn.grid(row=r, column=c)
           row_buttons.append(btn)
       buttons.append(row_buttons)
   # Disable the controls while the game is in progress
   size_menu.config(state="disabled")
   diff_menu.config(state="disabled")
   algo_menu.config(state="disabled")
   start_button.config(state="disabled")
   # (Human will make the first move by clicking on a cell)

def player_move(r, c):
   """Handle the human player's move at cell (r, c)."""
   # If the game is over or cell not empty, ignore the click
   if not board or board[r][c] != "empty":
       return
   # Place human's marker (1 for human, display "X")
   board[r][c] = 'x'
   buttons[r][c].config(text="X", state="disabled")
   # Check if human wins with this move
   if check_win(r, c, player='x'):
       messagebox.showinfo("Game Over", "You win! 🎉")
       end_game()
       return
   # If no win, and board not full, get computer's move
   comp_move = get_computer_move()
   print(comp_move)
   if comp_move is None:
       # No move found (could be a draw or error in AI logic)
       messagebox.showinfo("Game Over", "It's a draw!")
       end_game()
       return
   comp_r, comp_c = comp_move
   # Place computer's marker (2 for computer, display "O")
   board[comp_r][comp_c] = 'o'
   buttons[comp_r][comp_c].config(text="O", state="disabled")
   # Check if computer wins
   if check_win(comp_r, comp_c, player='o'):
       messagebox.showinfo("Game Over", "Computer wins!")
       end_game()
       return
   # If no win, game continues (human can click next move)

def get_computer_move():
   """Query the Prolog AI for the computer's next move. Returns (row, col) tuple or None."""

   board_state = board
   print(type(board_state))
   player = 'o'
   depth = difficulty_var.get()
   # Query Prolog for the computer's move. We use Move as an output variable.

   query = f"computer_move(minimax, {board}, {depth}, {player}, Move)"
   print("Query: " + query)
   try:
       result = list(prolog.query(query))
       print(result)
   except Exception as e:
       # If there's an error in querying Prolog, print it for debugging and return None
       print("Prolog query error:", e)
       return None
   if result:
       # Extract the Move from the first (and presumably only) result
       move = result[0]["Move"]
       striped_move = move.lstrip(",").strip()[1:-1]

       coordinates = [int(part.strip()) for part in striped_move.split(",")]



       return (coordinates[0], coordinates[1])
   return None

def check_win(r, c, player):
   """Check if placing a stone at (r, c) for the given player caused a five-in-a-row win."""
   # We will check all directions around (r,c) for 5 in a row of 'player'.
   # Since this function is called right after a move by 'player' at (r,c),
   # we know (r,c) contains 'player'.
   return find_five_in_a_row(player)

def find_five_in_a_row(player):
   """Scan the board to see if the given player has five in a row anywhere."""
   N = len(board)
   # Check all rows for 5 consecutive
   for i in range(N):
       count = 0
       for j in range(N):
           count = count + 1 if board[i][j] == player else 0
           if count >= 5:
               return True
   # Check all columns for 5 consecutive
   for j in range(N):
       count = 0
       for i in range(N):
           count = count + 1 if board[i][j] == player else 0
           if count >= 5:
               return True
   # Check down-right diagonals (bottom-right direction)
   for i in range(N):
       for j in range(N):
           if board[i][j] == player:
               # Check diagonal starting at (i,j)
               k = 0
               while i+k < N and j+k < N and board[i+k][j+k] == player:
                   k += 1
               if k >= 5:
                   return True
   # Check down-left diagonals (bottom-left direction)
   for i in range(N):
       for j in range(N):
           if board[i][j] == player:
               # Check diagonal starting at (i,j) going down-left
               k = 0
               while i+k < N and j-k >= 0 and board[i+k][j-k] == player:
                   k += 1
               if k >= 5:
                   return True
   return False

def end_game():
   """Handle cleanup after game over: disable board and re-enable controls."""
   # Disable all board buttons (no further moves allowed)
   for row in buttons:
       for btn in row:
           btn.config(state="disabled")
   # Re-enable the option selectors and start button for a new game
   size_menu.config(state="normal")
   diff_menu.config(state="normal")
   algo_menu.config(state="normal")
   start_button.config(state="normal")

# Top frame for settings
controls_frame = tk.Frame(root)
controls_frame.pack(pady=5)

tk.Label(controls_frame, text="Board Size:").grid(row=0, column=0, padx=5)
size_menu = tk.OptionMenu(controls_frame, board_size_var, *[str(n) for n in range(10, 16)])
size_menu.grid(row=0, column=1, padx=5)

tk.Label(controls_frame, text="Difficulty:").grid(row=0, column=2, padx=5)
diff_menu = tk.OptionMenu(controls_frame, difficulty_var, "1", "2", "3")
diff_menu.grid(row=0, column=3, padx=5)


start_button = tk.Button(controls_frame, text="Start Game", command=start_game, bg="#4CAF50", fg="white")
start_button.grid(row=0, column=5, padx=10)

# Frame for the game board grid
board_frame = tk.Frame(root)
board_frame.pack(pady=5)

# Start the Tkinter event loop
root.mainloop()







