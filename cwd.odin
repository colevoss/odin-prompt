package main

import "core:os"

CWD :: struct {
	cwd: string,
}

cwd_init :: proc(cwd: ^CWD, allocator := context.allocator) {
	cwd.cwd = os.get_current_directory(allocator)
}
