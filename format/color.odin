package format

import "core:fmt"

Color :: enum {
	Black        = 30,
	Red          = 31,
	Green        = 32,
	Yellow       = 33,
	Blue         = 34,
	Magenta      = 35,
	Cyan         = 36,
	LightGray    = 37,
	Gray         = 90,
	LightRed     = 91,
	LightGreen   = 92,
	LightYellow  = 93,
	LightBlue    = 94,
	LightMagenta = 95,
	LightCyan    = 96,
	White        = 97,
}

color :: proc(c: Color, msg: string) -> string {
	return fmt.aprintf("\033[%dm%s\033[0m", c, msg)
}
