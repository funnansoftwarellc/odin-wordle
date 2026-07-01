package wordle

import "core:math/rand"
import "core:slice"
import "core:strings"
import "core:time"

// The game model and rules. This layer is deliberately free of any rendering or
// platform (karl2d) dependency -- it is a pure simulation that can be driven and
// inspected without a window.

WORD_LENGTH      :: 5
MAX_GUESSES      :: 6
MESSAGE_LIFETIME :: 1 * time.Second

Letter :: enum {
	None,
	A,
	B,
	C,
	D,
	E,
	F,
	G,
	H,
	I,
	J,
	K,
	L,
	M,
	N,
	O,
	P,
	Q,
	R,
	S,
	T,
	U,
	V,
	W,
	X,
	Y,
	Z,
	Enter,
	Delete,
}

LetterState :: enum {
	Default,
	Absent,
	Present,
	Correct,
}

GameState :: enum {
	Playing,
	Won,
	Lost,
}

Guess :: struct {
	letter: Letter,
	state:  LetterState,
}

Row :: struct {
	letters: [WORD_LENGTH]Guess,
}

Message :: struct {
	text: string,
	// How long the message has been on screen; removed once it passes
	// MESSAGE_LIFETIME (see update_messages).
	age:  time.Duration,
}

GameBoard :: struct {
	messages:       [dynamic]Message,
	rows:           [MAX_GUESSES]Row,
	// Indexed by the full Letter enum for convenience, but None/Enter/Delete
	// never get a meaningful state -- only A..Z are ever written.
	keyboard_state: [Letter]LetterState,
	size:           f32,
	spacing:        f32,
	active_row:     int,
	builder:        strings.Builder,
	elapsed_time:   time.Duration,
	state:          GameState,
	target_word:    string,
}

// The dictionary of valid guesses; the target is drawn from it. Immutable data,
// so @(rodata); a variable rather than a constant only so it can be sliced.
@(rodata)
WORD_LIST := [?]string {
	"APPLE",
	"BANJO",
	"CRANE",
	"DELTA",
	"EAGLE",
	"FABLE",
	"MEETS",
	"PEEVE",
	"QUILT",
}

new_game :: proc() -> GameBoard {
	game_board := GameBoard{}
	game_board.state = .Playing
	game_board.size = 70
	game_board.spacing = 5
	strings.builder_init(&game_board.builder)
	game_board.target_word = WORD_LIST[rand.int_range(0, len(WORD_LIST))]
	return game_board
}

// Free the game board's owned resources.
destroy_game_board :: proc(game_board: ^GameBoard) {
	delete(game_board.messages)
	strings.builder_destroy(&game_board.builder)
}

// Tear down the current board and start a fresh one in place.
reset_game :: proc(game_board: ^GameBoard) {
	destroy_game_board(game_board)
	game_board^ = new_game()
}

get_active_row :: proc(game_board: ^GameBoard) -> ^Row {
	return &game_board.rows[game_board.active_row]
}

process_key :: proc(game_board: ^GameBoard, letter: Letter) {
	// Prevent inputs once the game is over.
	if game_board.state != .Playing {
		return
	}

	active_row := get_active_row(game_board)

	// Fill active row.
	if letter != .None && letter != .Enter && letter != .Delete {
		for &guess in active_row.letters {
			if guess.letter != .None {
				continue
			}

			guess.letter = letter
			break
		}
	} else if letter == .Delete {
		// Remove last letter from active row.
		#reverse for &guess in active_row.letters {
			if guess.letter != .None {
				guess.letter = .None
				break
			}
		}
	} else if letter == .Enter {
		submit_active_row(game_board)
	}
}

submit_active_row :: proc(game_board: ^GameBoard) {
	active_row := get_active_row(game_board)
	letters_to_string(active_row.letters, &game_board.builder)
	guess := strings.to_string(game_board.builder)

	msg_not_in_list :: "Not in word list"
	msg_not_enough_letters :: "Not enough letters"

	if len(guess) < WORD_LENGTH {
		append(&game_board.messages, Message{msg_not_enough_letters, 0})
		return
	}

	if !slice.contains(WORD_LIST[:], guess) {
		append(&game_board.messages, Message{msg_not_in_list, 0})
		return
	}

	target := string_to_letters(game_board.target_word)

	// Count each target letter so duplicates are scored correctly.
	target_letter_count: [Letter]int
	for letter in target {
		target_letter_count[letter] += 1
	}

	// First pass: exact position matches.
	for &g, i in active_row.letters {
		g.state = .Absent
		if g.letter == target[i] {
			g.state = .Correct
			target_letter_count[g.letter] -= 1
		}
	}

	// Second pass: right letter, wrong position, if the target still has one left.
	for &g in active_row.letters {
		if g.state != .Correct && target_letter_count[g.letter] > 0 {
			g.state = .Present
			target_letter_count[g.letter] -= 1
		}
	}

	// Update keyboard state with best state.
	for letter in active_row.letters {
		if letter.state > game_board.keyboard_state[letter.letter] {
			game_board.keyboard_state[letter.letter] = letter.state
		}
	}

	success := true
	for guess in active_row.letters {
		if guess.state != .Correct {
			success = false
			break
		}
	}

	if success {
		game_board.state = .Won
		append(&game_board.messages, Message{"You won!", 0})
	} else if game_board.active_row == len(game_board.rows) - 1 {
		game_board.state = .Lost
		append(&game_board.messages, Message{"You lost!", 0})
	}

	if game_board.active_row < len(game_board.rows) - 1 {
		game_board.active_row += 1
	}
}

update_messages :: proc(game_board: ^GameBoard) {
	for &message in game_board.messages {
		message.age += game_board.elapsed_time
	}

	// Reverse to safely remove message while iterating.
	#reverse for message, i in game_board.messages {
		if message.age >= MESSAGE_LIFETIME {
			ordered_remove(&game_board.messages, i)
		}
	}
}
