package wordle

import "core:fmt"
import "core:mem"
import "core:time"
import "core:strings"
import k2 "karl2d"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

game_board: GameBoard

// core:mem is only referenced by the debug tracking allocator in main().
_ :: mem

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
	init()
	defer shutdown()
	for step() {}
}

init :: proc() {
	k2.init(WINDOW_WIDTH, WINDOW_HEIGHT, "Wordle", {.Windowed_Resizable, false, false})
	// Offset onto a secondary monitor to the right of a WINDOW_WIDTH-wide primary.
	k2.set_window_position(WINDOW_WIDTH, 360)

	game_board.builder = strings.builder_from_bytes(game_board.builder_buff[:]) // init a string builder whith a static array

	if !load_word_list() {
		// The list is embedded at build time and verified to parse, so this should
		// never happen at runtime; log rather than crash, leaving game_board zeroed.
		fmt.eprintln("Failed to load word list from embedded words.json")
		return
	}
	reset_game(&game_board)
	game_board.prev_time = time.now()
}

step :: proc() -> bool {
	if !k2.update() {
		return false
	}

	now := time.now()
	game_board.elapsed_time = time.diff(game_board.prev_time, now)
	game_board.prev_time = now

	handle_input(&game_board)
	update_messages(&game_board)

	k2.clear(k2.BLACK)
	render_game_board(&game_board)
	render_messages(&game_board)
	k2.present()

	return true
}

shutdown :: proc() {
	destroy_word_list()
	k2.shutdown()
}
