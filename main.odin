package main

import rl "vendor:raylib"

// Draws a single frame. Marked `"c"` so it can be used directly as the
// emscripten main-loop callback on the web target.
update :: proc "c" () {
	rl.BeginDrawing()
	rl.ClearBackground(rl.DARKGRAY)
	rl.DrawText("Hello, World!", 190, 200, 20, rl.ORANGE)
	rl.DrawTriangle({400, 100}, {350, 200}, {450, 200}, rl.GREEN)
	rl.EndDrawing()
}

when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
	// Provided by emscripten at link time. A normal blocking
	// `for !rl.WindowShouldClose()` loop never yields back to the browser,
	// so on the web we hand the frame callback to emscripten instead.
	@(default_calling_convention = "c")
	foreign _ {
		emscripten_set_main_loop :: proc(cb: proc "c" (), fps: i32, simulate_infinite_loop: i32) ---
	}
}

main :: proc() {
	flags: rl.ConfigFlags = {.WINDOW_RESIZABLE}
	rl.SetConfigFlags(flags)
	rl.InitWindow(800, 600, "Odin Raylib Example")

	when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
		// fps = 0 -> drive the loop with requestAnimationFrame.
		emscripten_set_main_loop(update, 0, 1)
	} else {
		defer rl.CloseWindow()
		rl.SetTargetFPS(60)
		for !rl.WindowShouldClose() {
			update()
		}
	}
}
