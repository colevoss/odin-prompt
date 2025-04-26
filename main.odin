package main

import "cmd"
import "core:fmt"
import "core:os"
import "format"
import "git"

main :: proc() {
	args := os.args[1:]

	pwd := ""

	if len(args) > 0 {
		pwd = args[0]
	}

	status_command := cmd.Command {
		pwd     = pwd,
		command = {"git", "status", "--porcelain=v2", "--branch", "--untracked=all"},
	}


	if err := cmd.run(&status_command); err != nil {
		fmt.printf("error running command: %s", err)
		return
	}

	defer cmd.command_destory(&status_command)

	base_command := cmd.Command {
		pwd     = pwd,
		command = {"git", "rev-parse", "--show-toplevel"},
	}

	if err := cmd.run(&base_command); err != nil {
		fmt.printfln("error running base command: %s", err)
		return
	}

	defer cmd.command_destory(&base_command)

	fmt.println(base_command.lines)

	gs: git.GitStatus
	git.parse_status_from_command(&gs, &status_command)

	//str := format.color(.Blue, gs.head)
	//fmt.print(str)

	gb: git.GitBase
	git.parse_base_from_command(&gb, &base_command)

	fmt.println(gb.base)
}
