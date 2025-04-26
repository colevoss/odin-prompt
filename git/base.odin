package git

import "../cmd"
import "core:path/filepath"

GitBase :: struct {
	dir:  string,
	base: string,
}

parse_base_from_command :: proc(base: ^GitBase, command: ^cmd.Command) {
	assert(len(command.lines) >= 1, "command has no result lines")
	git_dir := command.lines[0]

	base.base = filepath.base(git_dir)
}
