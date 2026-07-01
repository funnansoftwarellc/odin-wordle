package wordle

import "core:fmt"
import "core:mem"
import "core:time"
import k2 "karl2d"

// The application shell: owns the window and the main loop, and wires the
// layers together each frame (input -> update -> render). It knows about
// karl2d, but the game model does not know about it.

WINDOW_WIDTH  :: 1280
WINDOW_HEIGHT :: 720

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	game_board := new_game()
	defer destroy_game_board(&game_board)

	init()

	start_time := time.now()

	for step(&game_board) {
		current_time := time.now()
		game_board.elapsed_time = time.diff(start_time, current_time)
		start_time = current_time
	}

	shutdown()
}

init :: proc() {
	k2.init(WINDOW_WIDTH, WINDOW_HEIGHT, "Wordle", {.Windowed_Resizable, false, false})
	// Offset onto a secondary monitor to the right of a WINDOW_WIDTH-wide primary.
	k2.set_window_position(WINDOW_WIDTH, 360)
}

step :: proc(game_board: ^GameBoard) -> bool {
	if !k2.update() {
		return false
	}

	handle_input(game_board)
	update_messages(game_board)

	k2.clear(k2.BLACK)
	render_game_board(game_board)
	render_messages(game_board)
	k2.present()

	return true
}

shutdown :: proc() {
	k2.shutdown()
}
