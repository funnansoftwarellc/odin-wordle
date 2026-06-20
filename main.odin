package hello_world

import k2 "karl2d"

main :: proc() {
	init()
	for step() {}
	shutdown()
}

init :: proc() {
	k2.init(1280, 720, "Greetings from Karl2D!", {.Windowed_Resizable, false, false})
}

step :: proc() -> bool {
	if !k2.update() {
		return false
	}

	k2.clear(k2.LIGHT_BLUE)
	k2.draw_text("Hellope!", {50, 50}, 100, k2.DARK_BLUE)
	k2.present()

	return true
}

shutdown :: proc() {
	k2.shutdown()
}
