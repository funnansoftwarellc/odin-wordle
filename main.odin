package wordle

import "core:fmt"
import "core:reflect"
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

GameBoard :: struct {
	rows:          [6]Row,
	letter_states: [Letter]LetterState,
	color_states:  [LetterState]k2.Color,
	size:          f32,
	spacing:       f32,
}

main :: proc() {
	game_board := GameBoard{}
	game_board.size = 70
	game_board.spacing = 5
	game_board.color_states[LetterState.Default] = k2.DARK_GRAY
	game_board.color_states[LetterState.Absent] = k2.DARK_GRAY
	game_board.color_states[LetterState.Present] = {181, 159, 59, 255}
	game_board.color_states[LetterState.Correct] = {83, 141, 78, 255}


	game_board.rows[0].letters = [5]Letter{Letter.A, Letter.B, Letter.C, Letter.D, Letter.E}
	game_board.letter_states[Letter.A] = LetterState.Correct
	game_board.letter_states[Letter.B] = LetterState.Present
	game_board.letter_states[Letter.C] = LetterState.Absent
	game_board.letter_states[Letter.D] = LetterState.Default
	game_board.letter_states[Letter.E] = LetterState.Default

	init(game_board)
	for step(game_board) {}
	shutdown()
}

init :: proc(game_board: GameBoard) {
	k2.init(1280, 720, "Greetings from Karl2D!", {.Windowed_Resizable, false, false})
	k2.set_window_position(1280, 360)
}

step :: proc(game_board: GameBoard) -> bool {
	if !k2.update() {
		return false
	}

	k2.clear(k2.BLACK)

	render_game_board(game_board)

	k2.present()

	return true
}

shutdown :: proc() {
	k2.shutdown()
}

render_game_board :: proc(game_board: GameBoard) {
	board_width: f32 = game_board.size * 5 + game_board.spacing * 4
	screen_size := k2.get_screen_size()

	x: f32 = (screen_size.x - board_width) * 0.5
	y: f32 = game_board.spacing

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
