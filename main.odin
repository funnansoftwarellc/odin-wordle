#+feature dynamic-literals

package wordle

import "core:fmt"
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
}

LetterState :: enum {
	Default,
	Absent,
	Present,
	Correct,
}

Row :: struct {
	letters: [5]Letter,
}

Dictionary :: struct {
	words:  [dynamic]string,
	target: int,
}

Message :: struct {
	text:     string,
	duration: time.Duration,
}

GameBoard :: struct {
	messages:      [dynamic]Message,
	rows:          [6]Row,
	letter_states: [Letter]LetterState,
	color_states:  [LetterState]k2.Color,
	size:          f32,
	spacing:       f32,
	active_row:    int,
	builder:       strings.Builder,
	elapsed_time:  time.Duration,
}

get_active_row :: proc(game_board: ^GameBoard) -> ^Row {
	return &game_board.rows[game_board.active_row]
}

submit_active_row :: proc(game_board: ^GameBoard, dictionary: ^Dictionary) {

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

	for word in dictionary.words {
		if guess == word {
			valid_word = true
			break
		}
	}

	if !valid_word {
		append(&game_board.messages, Message{msg_not_in_list, 0})
		return
	}

	target_word := dictionary.words[dictionary.target]

	if guess == target_word {
		fmt.println("You win!")
		return
	}

	if game_board.active_row < len(game_board.rows) - 1 {
		game_board.active_row += 1
	}
}

main :: proc() {
	game_board := GameBoard{}
	game_board.size = 70
	game_board.spacing = 5
	game_board.color_states[.Default] = k2.DARK_GRAY
	game_board.color_states[.Absent] = k2.DARK_GRAY
	game_board.color_states[.Present] = {181, 159, 59, 255}
	game_board.color_states[.Correct] = {83, 141, 78, 255}

	defer delete(game_board.messages)

	strings.builder_init(&game_board.builder)
	defer strings.builder_destroy(&game_board.builder)

	dictionary := Dictionary{}
	dictionary.target = 2
	dictionary.words = [dynamic]string{"APPLE", "BANJO", "CRANE", "DELTA", "EAGLE", "FABLE"}
	defer delete(dictionary.words)

	init(&game_board)

	start_time := time.now()

	for step(&game_board, &dictionary) {
		current_time := time.now()
		game_board.elapsed_time = time.diff(start_time, current_time)
		start_time = current_time
	}

	shutdown()
}

init :: proc(game_board: ^GameBoard) {
	k2.init(1280, 720, "Greetings from Karl2D!", {.Windowed_Resizable, false, false})
	k2.set_window_position(1280, 360)
}

step :: proc(game_board: ^GameBoard, dictionary: ^Dictionary) -> bool {
	if !k2.update() {
		return false
	}

	// Inputs
	active_row := get_active_row(game_board)

	for event, i in k2.get_events() {
		#partial switch e in event {
		case k2.Event_Key_Went_Down:
			current_letter := keys_to_letters(e.key)

			// Fill active row.
			if current_letter != .None {
				for &letter in active_row.letters {
					if letter != Letter.None {
						continue
					}

					letter = current_letter
					break
				}
			} else if e.key == k2.Keyboard_Key.Backspace {
				// Remove last letter from active row.
				#reverse for &letter in active_row.letters {
					if letter != Letter.None {
						letter = Letter.None
						break
					}
				}
			} else if e.key == k2.Keyboard_Key.Enter {
				submit_active_row(game_board, dictionary)
			}
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
		for letter, _ in row.letters {
			state := game_board.letter_states[letter]

			switch state {
			case LetterState.Default:
				k2.draw_rect_outline(
					{x, y, game_board.size, game_board.size},
					2,
					game_board.color_states[state],
				)
			case LetterState.Absent:
				k2.draw_rect(
					{x, y, game_board.size, game_board.size},
					game_board.color_states[state],
				)
			case LetterState.Present:
				k2.draw_rect(
					{x, y, game_board.size, game_board.size},
					game_board.color_states[state],
				)
			case LetterState.Correct:
				k2.draw_rect(
					{x, y, game_board.size, game_board.size},
					game_board.color_states[state],
				)
			}

			if letter != Letter.None {
				text := reflect.enum_string(letter)
				text_size := k2.measure_text(text, game_board.size)
				text_centered_x := x + (game_board.size - text_size.x) * 0.5
				text_centered_y := y + (game_board.size - text_size.y) * 0.5

				k2.draw_text(text, {text_centered_x, text_centered_y}, game_board.size, k2.WHITE)
			}

			x += game_board.size + game_board.spacing
		}

		y += game_board.size + game_board.spacing
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
	}

	return .None
}

letters_to_string :: proc(letters: [5]Letter, builder: ^strings.Builder) {
	strings.builder_reset(builder)

	for letter, _ in letters {
		if letter == Letter.None {
			continue
		}

		strings.write_string(builder, reflect.enum_string(letter))
	}
}
