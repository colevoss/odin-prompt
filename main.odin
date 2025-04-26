package main

import "cmd"
import "core:fmt"
import "core:os"
import "git"

main :: proc() {
	args := os.args[1:]

	pwd := ""

	if len(args) > 0 {
		pwd = args[0]
	}

	command := cmd.Command {
		pwd     = pwd,
		command = {"git", "status", "--porcelain=v2", "--branch", "--untracked=all"},
	}

	if err := cmd.run(&command); err != nil {
		fmt.printf("error running command: %s", err)
		return
	}

	if !command.state.success {
		os.exit(command.state.exit_code)
	}

	fmt.println("ec:", command.state.exit_code, command.state.success)

	gs: git.GitStatus
	git.parse_status_line(&gs, &command)

	//for l in command.lines {
	//	fmt.println(l)
	//}
}
