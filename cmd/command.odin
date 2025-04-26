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
}

run :: proc(cmd: ^Command) -> os.Error {
	//in_r, in_w := os.pipe() or_return
	out_r, out_w := os.pipe() or_return
	//err_r, err_w := os.pipe() or_return

	defer os.close(out_r)

	p: os.Process;{
		defer os.close(out_w)

		p = os.process_start(
		{
			working_dir = cmd.pwd,
			command     = cmd.command,
			stdout      = out_w,
			// stdin = in_r
		},
		) or_return
	}

	cmd.p = p

	lines: [dynamic]string
	buf: [1024]byte
	r: bufio.Reader

	bufio.reader_init_with_buf(&r, out_r.stream, buf[:])
	defer bufio.reader_destroy(&r)

	for {
		line, err := bufio.reader_read_string(&r, '\n', context.allocator)

		if err == io.Error.EOF {
			break
		}

		if err != nil {
			return err
		}

		line = strings.trim_right(line, "\r\n")
		append(&lines, line)
	}

	state := os.process_wait(p) or_return
	cmd.state = state

	cmd.lines = lines[:]

	return nil
}
