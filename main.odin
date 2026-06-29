#+feature dynamic-literals

package wordle

import "core:fmt"
import "core:math/rand"
import "core:reflect"
import "core:strings"
import "core:time"
import k2 "karl2d"

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
	letters: [5]Guess,
}

Message :: struct {
	text:     string,
	duration: time.Duration,
}

GameBoard :: struct {
	messages:       [dynamic]Message,
	rows:           [6]Row,
	keyboard_state: [Letter]LetterState,
	keyboard:       [dynamic][dynamic]Letter,
	color_states:   [LetterState]k2.Color,
	size:           f32,
	spacing:        f32,
	active_row:     int,
	builder:        strings.Builder,
	elapsed_time:   time.Duration,
	state:          GameState,
	words:          [dynamic]string,
	target_word:    string,
}

main :: proc() {
	game_board := new_game()

	defer delete(game_board.keyboard)
	defer delete(game_board.messages)

	strings.builder_init(&game_board.builder)
	defer strings.builder_destroy(&game_board.builder)
	defer delete(game_board.words)

	init(&game_board)

	start_time := time.now()

	for step(&game_board) {
		current_time := time.now()
		game_board.elapsed_time = time.diff(start_time, current_time)
		start_time = current_time
	}

	shutdown()
}

get_active_row :: proc(game_board: ^GameBoard) -> ^Row {
	return &game_board.rows[game_board.active_row]
}

submit_active_row :: proc(game_board: ^GameBoard) {

	valid_word := false
	active_row := get_active_row(game_board)
	letters_to_string(active_row.letters, &game_board.builder)
	guess := strings.to_string(game_board.builder)
	msg_not_in_list :: "Not in word list"
	msg_not_enough_letters :: "Not enough letters"

	if len(guess) < 5 {
		append(&game_board.messages, Message{msg_not_enough_letters, 0})
		return
	}

	for word in game_board.words {
		if guess == word {
			valid_word = true
			break
		}
	}

	if !valid_word {
		append(&game_board.messages, Message{msg_not_in_list, 0})
		return
	}

	target := string_to_letters(game_board.target_word)

	target_letter_count := make(map[Letter]int)
	defer delete(target_letter_count)

	for letter in target {
		target_letter_count[letter] += 1
	}

	for &g, i in active_row.letters {
		g.state = LetterState.Absent
		for t, k in target {
			if g.letter == t {
				if i == k {
					g.state = LetterState.Correct
					target_letter_count[g.letter] -= 1
				}
			}
		}
	}

	for &g, i in active_row.letters {
		for t, k in target {
			if g.letter == t &&
			   g.state != LetterState.Correct &&
			   target_letter_count[g.letter] > 0 {
				g.state = LetterState.Present
				target_letter_count[g.letter] -= 1
				break
			}
		}
	}

	for letter in active_row.letters {
		game_board.keyboard_state[letter.letter] = letter.state
	}

	success := true
	for guess in active_row.letters {
		if guess.state != LetterState.Correct {
			success = false
			break
		}
	}

	if success {
		game_board.state = GameState.Won
		append(&game_board.messages, Message{"You won!", 0})
	} else if game_board.active_row == len(game_board.rows) - 1 {
		game_board.state = GameState.Lost
		append(&game_board.messages, Message{"You lost!", 0})
	}

	if game_board.active_row < len(game_board.rows) - 1 {
		game_board.active_row += 1
	}
}


init :: proc(game_board: ^GameBoard) {
	k2.init(1280, 720, "Wordle", {.Windowed_Resizable, false, false})
	k2.set_window_position(1280, 360)
}

step :: proc(game_board: ^GameBoard) -> bool {
	if !k2.update() {
		return false
	}

	// Inputs
	active_row := get_active_row(game_board)

	for event, i in k2.get_events() {
		#partial switch e in event {
		case k2.Event_Key_Went_Down:
			current_letter := keys_to_letters(e.key)
			process_key(game_board, current_letter)
		}
	}

	// Update Messages
	update_messages(game_board)

	// Render
	k2.clear(k2.BLACK)

	render_game_board(game_board)
	render_messages(game_board)

	k2.present()

	return true
}

shutdown :: proc() {
	k2.shutdown()
}

new_game :: proc() -> GameBoard {
	game_board := GameBoard{}
	game_board.state = GameState.Playing
	game_board.size = 70
	game_board.spacing = 5
	game_board.color_states[.Default] = {130, 131, 135, 255}
	game_board.color_states[.Absent] = {58, 58, 60, 255}
	game_board.color_states[.Present] = {181, 159, 59, 255}
	game_board.color_states[.Correct] = {83, 141, 78, 255}

	append(
		&game_board.keyboard,
		[dynamic]Letter {
			Letter.Q,
			Letter.W,
			Letter.E,
			Letter.R,
			Letter.T,
			Letter.Y,
			Letter.U,
			Letter.I,
			Letter.O,
			Letter.P,
		},
	)

	append(
		&game_board.keyboard,
		[dynamic]Letter {
			Letter.A,
			Letter.S,
			Letter.D,
			Letter.F,
			Letter.G,
			Letter.H,
			Letter.J,
			Letter.K,
			Letter.L,
		},
	)

	append(
		&game_board.keyboard,
		[dynamic]Letter {
			Letter.Enter,
			Letter.Z,
			Letter.X,
			Letter.C,
			Letter.V,
			Letter.B,
			Letter.N,
			Letter.M,
			Letter.Delete,
		},
	)

	game_board.words = [dynamic]string {
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

	game_board.target_word = game_board.words[rand.int_range(0, len(game_board.words) - 1)]

	return game_board
}

process_key :: proc(game_board: ^GameBoard, letter: Letter) {
	active_row := get_active_row(game_board)

	// Fill active row.
	if letter != .None && letter != .Enter && letter != .Delete {
		for &guess in active_row.letters {
			if guess.letter != Letter.None {
				continue
			}

			guess.letter = letter
			break
		}
	} else if letter == .Delete {
		// Remove last letter from active row.
		#reverse for &guess in active_row.letters {
			if guess.letter != Letter.None {
				guess.letter = Letter.None
				break
			}
		}
	} else if letter == .Enter {
		submit_active_row(game_board)
	}
}

update_messages :: proc(game_board: ^GameBoard) {
	for &message in game_board.messages {
		message.duration += game_board.elapsed_time
	}

	// Reverse to safely remove message while iterating.
	#reverse for message, i in game_board.messages {
		if message.duration >= 1 * time.Second {
			ordered_remove(&game_board.messages, i)
		}
	}
}

render_game_board :: proc(game_board: ^GameBoard) {
	board_width: f32 = game_board.size * 5 + game_board.spacing * 4
	screen_size := k2.get_screen_size()

	x: f32 = (screen_size.x - board_width) * 0.5
	y: f32 = game_board.spacing

	// Render grid
	for row, _ in game_board.rows {
		x = (screen_size.x - board_width) * 0.5
		for guess, _ in row.letters {
			switch guess.state {
			case LetterState.Default:
				k2.draw_rect_outline(
					{x, y, game_board.size, game_board.size},
					2,
					game_board.color_states[.Absent],
				)
			case LetterState.Absent:
				k2.draw_rect(
					{x, y, game_board.size, game_board.size},
					game_board.color_states[guess.state],
				)
			case LetterState.Present:
				k2.draw_rect(
					{x, y, game_board.size, game_board.size},
					game_board.color_states[guess.state],
				)
			case LetterState.Correct:
				k2.draw_rect(
					{x, y, game_board.size, game_board.size},
					game_board.color_states[guess.state],
				)
			}

			if guess.letter != Letter.None {
				text := reflect.enum_string(guess.letter)
				text_size := k2.measure_text(text, game_board.size)
				text_centered_x := x + (game_board.size - text_size.x) * 0.5
				text_centered_y := y + (game_board.size - text_size.y) * 0.5

				k2.draw_text(text, {text_centered_x, text_centered_y}, game_board.size, k2.WHITE)
			}

			x += game_board.size + game_board.spacing
		}

		y += game_board.size + game_board.spacing
	}


	if game_board.state == GameState.Playing {

		key_width: f32 = game_board.size * 0.65

		y = screen_size.y - (game_board.size + game_board.spacing) * 3

		for row in game_board.keyboard {
			len := len(row)
			spaces := len - 1
			x = (screen_size.x - (key_width * f32(len) + game_board.spacing * f32(spaces))) * 0.5

			for key in row {
				// Intersect the key position and size.
				if k2.mouse_button_went_down(k2.Mouse_Button.Left) &&
				   k2.point_in_rect(k2.get_mouse_position(), {x, y, key_width, game_board.size}) {

					process_key(game_board, key)
				}

				k2.draw_rect(
					{x, y, key_width, game_board.size},
					game_board.color_states[game_board.keyboard_state[key]],
				)

				text := reflect.enum_string(key)
				text_size := k2.measure_text(text, game_board.size * 0.5)
				text_centered_x := x + (key_width - text_size.x) * 0.5
				text_centered_y := y + (game_board.size - text_size.y) * 0.5

				k2.draw_text(
					text,
					{text_centered_x, text_centered_y},
					game_board.size * 0.5,
					k2.WHITE,
				)

				x += key_width + game_board.spacing
			}

			y += game_board.size + game_board.spacing
		}
	} else {
		rect := k2.Rect{(screen_size.x - 150) * 0.5, y, 150, 50}


		if k2.mouse_button_went_down(k2.Mouse_Button.Left) &&
		   k2.point_in_rect(k2.get_mouse_position(), rect) {

			game_board^ = new_game()
		}

		k2.draw_rect_outline(rect, 4, k2.WHITE)

		text_size := k2.measure_text("New Game", 24)
		text_centered_x := rect.x + (rect.w - text_size.x) * 0.5
		text_centered_y := rect.y + (rect.h - text_size.y) * 0.5

		k2.draw_text("New Game", {text_centered_x, text_centered_y}, 24, k2.WHITE)
	}
}

render_messages :: proc(game_board: ^GameBoard) {
	screen_size := k2.get_screen_size()

	rect_y := game_board.spacing * 2

	for message, _ in game_board.messages {
		text_size := k2.measure_text(message.text, 24)
		text_spacing :: 10
		rect_width := text_size.x + (text_spacing * 2)
		rect_height := text_size.y + (text_spacing * 2)
		rect_x := (screen_size.x - rect_width) * 0.5

		k2.draw_rect({rect_x, rect_y, rect_width, rect_height}, k2.WHITE)

		text_centered_x := rect_x + (rect_width - text_size.x) * 0.5
		text_centered_y := rect_y + (rect_height - text_size.y) * 0.5
		k2.draw_text(message.text, {text_centered_x, text_centered_y}, 24, k2.BLACK)

		rect_y += rect_height + game_board.spacing * 2
	}
}

keys_to_letters :: proc(key: k2.Keyboard_Key) -> Letter {
	#partial switch key {
	case .A:
		return Letter.A
	case .B:
		return Letter.B
	case .C:
		return Letter.C
	case .D:
		return Letter.D
	case .E:
		return Letter.E
	case .F:
		return Letter.F
	case .G:
		return Letter.G
	case .H:
		return Letter.H
	case .I:
		return Letter.I
	case .J:
		return Letter.J
	case .K:
		return Letter.K
	case .L:
		return Letter.L
	case .M:
		return Letter.M
	case .N:
		return Letter.N
	case .O:
		return Letter.O
	case .P:
		return Letter.P
	case .Q:
		return Letter.Q
	case .R:
		return Letter.R
	case .S:
		return Letter.S
	case .T:
		return Letter.T
	case .U:
		return Letter.U
	case .V:
		return Letter.V
	case .W:
		return Letter.W
	case .X:
		return Letter.X
	case .Y:
		return Letter.Y
	case .Z:
		return Letter.Z
	case .Enter:
		return Letter.Enter
	case .Backspace:
		return Letter.Delete
	}

	return .None
}

letters_to_string :: proc(guess: [5]Guess, builder: ^strings.Builder) {
	strings.builder_reset(builder)

	for guess, _ in guess {
		if guess.letter == Letter.None {
			continue
		}

		strings.write_string(builder, reflect.enum_string(guess.letter))
	}
}

rune_to_letter :: proc(s: rune) -> Letter {
	switch s {
	case 'A':
		return Letter.A
	case 'B':
		return Letter.B
	case 'C':
		return Letter.C
	case 'D':
		return Letter.D
	case 'E':
		return Letter.E
	case 'F':
		return Letter.F
	case 'G':
		return Letter.G
	case 'H':
		return Letter.H
	case 'I':
		return Letter.I
	case 'J':
		return Letter.J
	case 'K':
		return Letter.K
	case 'L':
		return Letter.L
	case 'M':
		return Letter.M
	case 'N':
		return Letter.N
	case 'O':
		return Letter.O
	case 'P':
		return Letter.P
	case 'Q':
		return Letter.Q
	case 'R':
		return Letter.R
	case 'S':
		return Letter.S
	case 'T':
		return Letter.T
	case 'U':
		return Letter.U
	case 'V':
		return Letter.V
	case 'W':
		return Letter.W
	case 'X':
		return Letter.X
	case 'Y':
		return Letter.Y
	case 'Z':
		return Letter.Z
	}

	return Letter.None
}

string_to_letters :: proc(s: string) -> [5]Letter {
	letters: [5]Letter

	for r, i in s {
		if i >= 5 {
			break
		}

		letters[i] = rune_to_letter(r)
	}

	return letters
}
