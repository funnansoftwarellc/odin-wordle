package wordle

import k2 "karl2d"

// The view layer: draws the game state with karl2d and owns the on-screen
// layout. It only reads the GameBoard -- it never mutates game state or handles
// input (see input.odin for that).

KEY_WIDTH_RATIO :: 0.65
// Enter and Delete render a whole word rather than a single glyph, so they get a
// wider key. 1.5x a letter key also keeps the three rows about equal width.
WIDE_KEY_SCALE  :: 1.5
UI_FONT_SIZE    :: 24
BUTTON_WIDTH    :: 150
BUTTON_HEIGHT   :: 50
GRID_OUTLINE    :: 2
BUTTON_OUTLINE  :: 4

// The Wordle palette, indexed by letter state. A variable (not a constant)
// because Odin only lets constant enum-arrays be indexed by constant keys.
@(rodata)
LETTER_COLORS := [LetterState]k2.Color {
	.Default = {130, 131, 135, 255},
	.Absent  = {58, 58, 60, 255},
	.Present = {181, 159, 59, 255},
	.Correct = {83, 141, 78, 255},
}

// Fixed QWERTY arrangement of the on-screen keyboard. Purely a presentation
// concern (drawing + click hit-testing); the game rules only care about the
// individual Letter values. Rows are ragged (10/9/9), hence a slice-of-slices.
@(rodata)
keyboard_layout := [3][]Letter {
	{.Q, .W, .E, .R, .T, .Y, .U, .I, .O, .P},
	{.A, .S, .D, .F, .G, .H, .J, .K, .L},
	{.Enter, .Z, .X, .C, .V, .B, .N, .M, .Delete},
}

// --- Layout geometry (shared with input.odin for hit-testing) ---

keyboard_key_width :: proc(game_board: ^GameBoard) -> f32 {
	return game_board.size * KEY_WIDTH_RATIO
}

// The width of one key. Enter and Delete are wider than the letter keys so their
// labels fit; every other key uses the base letter-key width.
keyboard_key_width_for :: proc(game_board: ^GameBoard, key: Letter) -> f32 {
	width := keyboard_key_width(game_board)
	if key == .Enter || key == .Delete {
		width *= WIDE_KEY_SCALE
	}
	return width
}

// Total laid-out width of a row: every key's width plus the gaps between them.
keyboard_row_width :: proc(game_board: ^GameBoard, row: []Letter) -> f32 {
	width := game_board.spacing * f32(len(row) - 1)
	for key in row {
		width += keyboard_key_width_for(game_board, key)
	}
	return width
}

keyboard_top_y :: proc(game_board: ^GameBoard, screen_size: k2.Vec2) -> f32 {
	// Three rows tall, anchored to the bottom of the screen.
	return screen_size.y - (game_board.size + game_board.spacing) * 3
}

keyboard_row_start_x :: proc(game_board: ^GameBoard, screen_size: k2.Vec2, row: []Letter) -> f32 {
	return (screen_size.x - keyboard_row_width(game_board, row)) * 0.5
}

new_game_button_rect :: proc(game_board: ^GameBoard, screen_size: k2.Vec2) -> k2.Rect {
	// Positioned explicitly just below the grid.
	board_height :=
		game_board.spacing + f32(len(game_board.rows)) * (game_board.size + game_board.spacing)
	return {(screen_size.x - BUTTON_WIDTH) * 0.5, board_height, BUTTON_WIDTH, BUTTON_HEIGHT}
}

// --- Drawing ---

draw_text_centered :: proc(text: string, rect: k2.Rect, font_size: f32, color: k2.Color) {
	text_size := k2.measure_text(text, font_size)
	pos := k2.Vec2 {
		rect.x + (rect.w - text_size.x) * 0.5,
		rect.y + (rect.h - text_size.y) * 0.5,
	}
	k2.draw_text(text, pos, font_size, color)
}

// Like draw_text_centered, but shrinks the font if the text would overflow the
// rect's width (minus a little horizontal padding). Single glyphs render at the
// requested size; multi-character labels like "Enter"/"Delete" scale down to fit.
draw_text_fit :: proc(text: string, rect: k2.Rect, font_size: f32, color: k2.Color) {
	TEXT_PADDING :: 8
	size := font_size
	max_width := rect.w - TEXT_PADDING * 2
	text_width := k2.measure_text(text, size).x
	if text_width > max_width && text_width > 0 {
		size *= max_width / text_width
	}
	draw_text_centered(text, rect, size, color)
}

render_game_board :: proc(game_board: ^GameBoard) {
	screen_size := k2.get_screen_size()
	board_width := game_board.size * WORD_LENGTH + game_board.spacing * (WORD_LENGTH - 1)

	// Render grid.
	y := game_board.spacing
	for row in game_board.rows {
		x := (screen_size.x - board_width) * 0.5
		for guess in row.letters {
			cell := k2.Rect{x, y, game_board.size, game_board.size}

			if guess.state == .Default {
				k2.draw_rect_outline(cell, GRID_OUTLINE, LETTER_COLORS[.Absent])
			} else {
				k2.draw_rect(cell, LETTER_COLORS[guess.state])
			}

			if guess.letter != .None {
				draw_text_centered(LETTER_TEXT[guess.letter], cell, game_board.size, k2.WHITE)
			}

			x += game_board.size + game_board.spacing
		}
		y += game_board.size + game_board.spacing
	}

	if game_board.mode == .Playing {
		render_keyboard(game_board, screen_size)
	} else {
		render_new_game_button(game_board, screen_size)
	}
}

render_keyboard :: proc(game_board: ^GameBoard, screen_size: k2.Vec2) {
	y := keyboard_top_y(game_board, screen_size)

	for row in keyboard_layout {
		x := keyboard_row_start_x(game_board, screen_size, row)
		for key in row {
			key_width := keyboard_key_width_for(game_board, key)
			rect := k2.Rect{x, y, key_width, game_board.size}
			k2.draw_rect(rect, LETTER_COLORS[game_board.keyboard_state[key]])
			draw_text_fit(LETTER_TEXT[key], rect, game_board.size * 0.5, k2.WHITE)
			x += key_width + game_board.spacing
		}
		y += game_board.size + game_board.spacing
	}
}

render_new_game_button :: proc(game_board: ^GameBoard, screen_size: k2.Vec2) {
	rect := new_game_button_rect(game_board, screen_size)
	k2.draw_rect_outline(rect, BUTTON_OUTLINE, k2.WHITE)
	draw_text_centered("New Game", rect, UI_FONT_SIZE, k2.WHITE)
}

render_messages :: proc(game_board: ^GameBoard) {
	screen_size := k2.get_screen_size()

	rect_y := game_board.spacing * 2

	for message in game_board.messages {
		text_size := k2.measure_text(message.text, UI_FONT_SIZE)
		text_spacing :: 10
		rect_width := text_size.x + text_spacing * 2
		rect_height := text_size.y + text_spacing * 2
		rect := k2.Rect{(screen_size.x - rect_width) * 0.5, rect_y, rect_width, rect_height}

		k2.draw_rect(rect, k2.WHITE)
		draw_text_centered(message.text, rect, UI_FONT_SIZE, k2.BLACK)

		rect_y += rect_height + game_board.spacing * 2
	}
}
