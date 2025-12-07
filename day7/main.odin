package day7

import "core:bufio"
import "core:fmt"
import "core:os"
import "core:strings"

PART1 :: 1
PART2 :: 2

main :: proc() {
	part: int
	if len(os.args) < 2 {
		panic("usage: app <filename> <part>")
	}

	fmt.printfln("Processing file %v", os.args[1])

	if os.args[2] == "1" {
		part = PART1
	} else if os.args[2] == "2" {
		part = PART2
	} else {
		panic("specify part 1 or 2")
	}

	handle, err := os.open(os.args[1])
	if err != os.General_Error.None do return
	defer os.close(handle)

	s := os.stream_from_handle(handle)
	r: bufio.Reader
	bufio.reader_init(&r, s)
	defer bufio.reader_destroy(&r)

	state: [dynamic]int
	result: int

	for {
		line := read_line(&r, context.temp_allocator) or_break
		defer free_all(context.temp_allocator)

		if state == nil {
			state = make([dynamic]int, len(line))
		}

		splits: int
		for c, i in line {
			if c == 'S' {
				spawn_ray(state[:], i)
			} else if c == '^' {
				splits += split_ray(state[:], i)
			}
		}
		result += splits
		//print_state(line, state[:], splits)
	}

	switch part {
	case PART1:
	case PART2:
		result = sum(state[:])
	}
	fmt.printfln("Total splits: %v", result)
}

print_state :: proc(line: string, state: []int, x: int) {
	for c, i in state {
		if line[i] == '^' {
			fmt.print('^')
		} else if line[i] == 'S' {
			fmt.print('S')
		} else if c == 0 {
			fmt.print('.')
		} else {
			fmt.print('|')
		}
	}
	fmt.printfln("  %v", x)
}

spawn_ray :: proc(state: []int, i: int) {
	state[i] = 1
}

split_ray :: proc(state: []int, i: int) -> (splits: int) {
	if state[i] > 0 {
		// skip boundary check based on input data aligment
		state[i - 1] += state[i]
		state[i + 1] += state[i]
		state[i] = 0
		splits = 1
	}
	return
}

sum :: proc(arr: []int) -> (result: int) {
	for i in arr do result += i
	return
}

read_line :: proc(
	r: ^bufio.Reader,
	allocator := context.temp_allocator,
) -> (
	line: string,
	ok: bool,
) {
	for {
		line = bufio.reader_read_string(r, '\n', allocator) or_break
		return strings.trim_space(line), true
	}
	return
}

