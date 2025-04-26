package git

import "../cmd"
import "core:fmt"
import "core:strings"

Status :: enum {
	None,
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
StatusCount :: [Status][2]int

Status_Index :: enum {
	Index,
	WorkingDir,
}

Status_Error :: enum {
	UnknownStatus,
}

GitStatus :: struct {
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

parse_status_from_command :: proc(status: ^GitStatus, command: ^cmd.Command) {
	branchLines := 0

	for line, i in command.lines {
		type := line_type(line)

		#partial switch type {
		case .Fatal:
			return

		case .Branch:
			branchLines += 1

			if branchLines == 2 {
				// # branch.head <BRANCH_NAME>
				status.head = line[14:]
			}

		case .Untracked:
			status_count_inc(status, .WorkingDir, .Untracked)
		case .Ignored:
			status_count_inc(status, .WorkingDir, .Ignored)
		case .ChangeEntry:
			parse_change_entry(status, line)
		}
	}

	//fmt.printfln("%v", status)
}

parse_change_entry :: proc(status: ^GitStatus, line: string) {
	assert(len(line) >= 4, "cannot parse change entry line with length < 4")

	index_symbol := line[2]
	wd_symbol := line[3]

	index_status := status_from_symbol(index_symbol)
	wd_status := status_from_symbol(wd_symbol)

	status_count_inc(status, .Index, index_status)
	status_count_inc(status, .WorkingDir, wd_status)
}

status_count_inc :: proc(status: ^GitStatus, index: Status_Index, type: Status) {
	status.statuses[type][index] += 1
}


line_type :: proc(line: string) -> LineType {
	if len(line) == 0 {
		return .Empty
	}

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
	case .None, .Unknown:
		return ""
	}

	return ""
}

// https://git-scm.com/docs/git-status
status_from_symbol :: proc(symbol: u8) -> Status {
	switch symbol {
	case '.':
		return .None
	case '?':
		return .Untracked
	case '!':
		return .Ignored
	case 'M':
		return .Modified
	case 'T':
		return .TypeChanged
	case 'A':
		return .Added
	case 'D':
		return .Deleted
	case 'R':
		return .Renamed
	case 'C':
		return .Copied
	case 'U':
		return .UpdatedUnmerged
	}

	return .Unknown
}
