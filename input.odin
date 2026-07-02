package wordle

import k2 "karl2d"

// The controller layer: turns platform input (karl2d keyboard events and mouse
// clicks) into game commands. It depends on karl2d and on the view's layout
// geometry, but the game model (game.odin) never depends on it.

handle_input :: proc(game_board: ^GameBoard) {
	for event in k2.get_events() {
		#partial switch e in event {
		case k2.Event_Key_Went_Down:
			process_key(game_board, keys_to_letters(e.key))
		}
	}

	handle_mouse_input(game_board)
}

keys_to_letters :: proc(key: k2.Keyboard_Key) -> Letter {
	// karl2d's Keyboard_Key.A..Z are the ASCII codes for 'A'..'Z', so the same
	// offset trick as rune_to_letter applies.
	if key >= .A && key <= .Z {
		return letter_from_offset(int(key) - int(k2.Keyboard_Key.A))
	}

	#partial switch key {
	case .Enter:
		return .Enter
	case .Backspace:
		return .Delete
	}

	return .None
}

// Route a left-click to the on-screen keyboard or the New Game button, using the
// same layout geometry the renderer draws with.
handle_mouse_input :: proc(game_board: ^GameBoard) {
	if !k2.mouse_button_went_down(.Left) {
		return
	}

	mouse := k2.get_mouse_position()
	screen_size := k2.get_screen_size()

	if game_board.mode == .Playing {
		y := keyboard_top_y(game_board, screen_size)

		for row in keyboard_layout {
			x := keyboard_row_start_x(game_board, screen_size, row)
			for key in row {
				key_width := keyboard_key_width_for(game_board, key)
				if k2.point_in_rect(mouse, {x, y, key_width, game_board.size}) {
					process_key(game_board, key)
					return
				}
				x += key_width + game_board.spacing
			}
			y += game_board.size + game_board.spacing
		}
	} else if k2.point_in_rect(mouse, new_game_button_rect(game_board, screen_size)) {
		reset_game(game_board)
	}
}
