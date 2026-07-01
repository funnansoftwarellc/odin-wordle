package wordle

import "core:strings"

// Pure conversions between the Letter enum and runes/strings. No platform or
// rendering dependency, so both the game rules and the view can share them.

// Letter -> display text, used by the renderer and by guess-string building.
// A variable (not a constant) because Odin only lets constant enum-arrays be
// indexed by constant keys, and these are looked up with runtime values.
@(rodata)
LETTER_TEXT := [Letter]string {
	.None   = "",
	.A      = "A",
	.B      = "B",
	.C      = "C",
	.D      = "D",
	.E      = "E",
	.F      = "F",
	.G      = "G",
	.H      = "H",
	.I      = "I",
	.J      = "J",
	.K      = "K",
	.L      = "L",
	.M      = "M",
	.N      = "N",
	.O      = "O",
	.P      = "P",
	.Q      = "Q",
	.R      = "R",
	.S      = "S",
	.T      = "T",
	.U      = "U",
	.V      = "V",
	.W      = "W",
	.X      = "X",
	.Y      = "Y",
	.Z      = "Z",
	.Enter  = "Enter",
	.Delete = "Delete",
}

// Letter's A..Z members are declared contiguously right after None, so a
// zero-based offset from 'A' maps straight onto the enum. Both keys_to_letters
// and rune_to_letter share this to keep the enum-ordering assumption in one place.
letter_from_offset :: proc(offset: int) -> Letter {
	return Letter(int(Letter.A) + offset)
}

letters_to_string :: proc(letters: [WORD_LENGTH]Guess, builder: ^strings.Builder) {
	strings.builder_reset(builder)

	for guess in letters {
		if guess.letter == .None {
			continue
		}

		strings.write_string(builder, LETTER_TEXT[guess.letter])
	}
}

rune_to_letter :: proc(r: rune) -> Letter {
	if r >= 'A' && r <= 'Z' {
		return letter_from_offset(int(r - 'A'))
	}

	return .None
}

string_to_letters :: proc(s: string) -> [WORD_LENGTH]Letter {
	letters: [WORD_LENGTH]Letter

	for r, i in s {
		if i >= WORD_LENGTH {
			break
		}

		letters[i] = rune_to_letter(r)
	}

	return letters
}
