package day1

import "core:bufio"
import "core:fmt"
import "core:math/linalg"
import "core:os"
import "core:strconv"

initial_position :: 50

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

	position := initial_position
	total_zero_cross := 0

	for {
		num, dir := process_line(&r) or_break
		
		prev_position := position
		switch dir {
		case 'L':
			position -= num
		case 'R':
			position += num
		}

		new_position, zero_cross: int
		switch part {
		case PART1:
			new_position, zero_cross = count_zero_crosses(prev_position, position)
		case PART2:
			new_position, zero_cross = count_zero_crosses_2(prev_position, position)
		}

		position = new_position
		total_zero_cross += zero_cross
	}

	fmt.printfln("Crossed zero %v times", total_zero_cross)
}

count_zero_crosses :: proc(prev_position, position: int) -> (new_position, zero_cross: int) {
	new_position = wrap(position, 100)
	if new_position == 0 {
		zero_cross += 1
	}
	return
}

count_zero_crosses_2 :: proc(prev_position, position: int) -> (new_position, zero_cross: int) {
	if prev_position != 0 && position != 0 && linalg.sign(prev_position) != linalg.sign(position) {
		zero_cross += 1
	}
	whole_rot := abs(position / 100)
	new_position = wrap(position, 100)
	if whole_rot > 0 {
		zero_cross += whole_rot
	} else if new_position == 0 {
		zero_cross += 1
	}
	return
}

process_line :: proc(r: ^bufio.Reader) -> (num: int, dir: u8, ok: bool) {
	for {
		line := bufio.reader_read_string(r, '\n', context.temp_allocator) or_break
		defer free_all(context.temp_allocator)
		num = strconv.parse_int(line[1:len(line) - 1]) or_return
		dir = line[0]

		return num, dir, true
	}
	return 0, 0, false
}

wrap :: proc(x, n: int) -> int {
	return ((x % n) + n) % n
}
