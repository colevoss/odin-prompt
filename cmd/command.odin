package cmd

import "core:bufio"
import "core:io"
import os "core:os/os2"
import "core:strings"

Command :: struct {
	p:       os.Process,
	state:   os.Process_State,
	pwd:     string,
	command: []string,
	lines:   []string,
	error:   string,
}

command_destory :: proc(c: ^Command) {
	delete(c.lines)
	delete(c.error)
}

run :: proc(cmd: ^Command, allocator := context.allocator) -> os.Error {
	//in_r, in_w := os.pipe() or_return
	stdout_r, stdout_w := os.pipe() or_return
	stderr_r, stderr_w := os.pipe() or_return

	defer os.close(stdout_r)
	defer os.close(stderr_r)

	p: os.Process;{
		// ensure writers close so readers can start
		defer os.close(stdout_w)
		defer os.close(stderr_w)

		p = os.process_start(
			{working_dir = cmd.pwd, command = cmd.command, stdout = stdout_w, stderr = stderr_w},
		) or_return
	}

	cmd.p = p

	lines: [dynamic]string
	buf: [1024]byte = ---
	out_reader: bufio.Reader
	bufio.reader_init_with_buf(&out_reader, stdout_r.stream, buf[:])
	defer bufio.reader_destroy(&out_reader)

	err_data: [dynamic]byte
	err_buf: [1024]byte = ---
	err_reader: bufio.Reader
	bufio.reader_init_with_buf(&err_reader, stderr_r.stream, err_buf[:])
	defer bufio.reader_destroy(&err_reader)

	stdout_has_data := true
	stderr_has_data := true

	for stdout_has_data || stderr_has_data {
		out_blk: {

			if stdout_has_data {
				line, err := bufio.reader_read_string(&out_reader, '\n', context.allocator)

				if err == io.Error.EOF {
					stdout_has_data = false
					break out_blk
				}

				if err != nil {
					return err
				}

				line = strings.trim_right(line, "\r\n")
				append(&lines, line)
			}
		}

		err_blk: {
			if stderr_has_data {
				n, err := bufio.reader_read(&err_reader, err_buf[:])

				#partial switch err {
				case nil:
					append(&err_data, ..err_buf[:n])
				case io.Error.EOF:
					stderr_has_data = false
					break err_blk
				case:
					return err
				}
			}
		}
	}

	cmd.lines = lines[:]
	cmd.error = strings.trim_right(string(err_data[:]), "\n")

	state, err := os.process_wait(p)
	cmd.state = state

	return err
}
