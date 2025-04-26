package git

import "../cmd"
import "core:fmt"
import "core:strings"

Status :: enum {
	Untracked,
	Ignored,
	Modified,
	TypeChanged,
	Added,
	Deleted,
	Renamed,
	Copied,
	UpdatedUnmerged,
	Unknown,
}

// For now just do indexed and workting tree counts
StatusCount :: [Status][1]int

status_count_inc :: proc(status: ^GitStatus, type: Status) {
	status.statuses[type][0] += 1
}

Status_Error :: enum {
	UnknownStatus,
}

GitStatus :: struct {
	is_repo:  bool,
	head:     string,
	statuses: StatusCount,
}

LineType :: enum {
	Fatal,
	Branch,
	ChangeEntry,
	Untracked,
	Ignored,
	Unmerged,
	Empty,
}

parse_status_line :: proc(status: ^GitStatus, cmd: ^cmd.Command) {
	branchLines := 0
	status.is_repo = true

	for line, i in cmd.lines {
		fmt.println(line)

		type := line_type(line)

		#partial switch type {
		case .Fatal:
			status.is_repo = false
			return

		case .Branch:
			branchLines += 1

			if branchLines == 2 {
				// # branch.head <BRANCH_NAME>
				status.head = line[14:]
			}

		case .Untracked:
			status_count_inc(status, .Untracked)
		//counts[.Untracked][0] += 1
		case .Ignored:
			status_count_inc(status, .Ignored)
		}
	}

	fmt.printfln("%v", status)
}

line_type :: proc(line: string) -> LineType {
	if len(line) == 0 {
		return .Empty
	}
	fmt.println("line", strings.index(line, "fatal"))

	switch line[0] {
	case '#':
		return .Branch
	case '?':
		return .Untracked
	case '!':
		return .Ignored
	case 'u':
		return .Unmerged
	case '1', '2':
		return .ChangeEntry
	}


	if strings.index(line, "fatal") > -1 {
		return .Fatal
	}

	fmt.panicf("expected line to be of known type. got %s", line)
}

// https://git-scm.com/docs/git-status
status_symbol :: proc(status: Status) -> string {
	switch status {
	case .Untracked:
		return "?"
	case .Ignored:
		return "!"
	case .Modified:
		return "M"
	case .TypeChanged:
		return "T"
	case .Added:
		return "A"
	case .Deleted:
		return "D"
	case .Renamed:
		return "R"
	case .Copied:
		return "C"
	case .UpdatedUnmerged:
		return "U"
	case .Unknown:
		return ""
	}

	return ""
}

// https://git-scm.com/docs/git-status
status_from_symbol :: proc(symbol: string) -> (Status, Status_Error) {
	switch symbol {
	case "?":
		return .Untracked, nil
	case "!":
		return .Ignored, nil
	case "M":
		return .Modified, nil
	case "T":
		return .TypeChanged, nil
	case "A":
		return .Added, nil
	case "D":
		return .Deleted, nil
	case "R":
		return .Renamed, nil
	case "C":
		return .Copied, nil
	case "U":
		return .UpdatedUnmerged, nil
	}

	return .Unknown, Status_Error.UnknownStatus
}
