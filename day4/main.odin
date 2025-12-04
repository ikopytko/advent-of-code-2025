package day4

import "core:bufio"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"

PART1 :: 1
PART2 :: 2

Board :: struct {
	size:        int,
	data:        []u8,
	back_buffer: []u8,
}

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


	board: Board
	i := 0
	for {
		line := read_line(&r, context.temp_allocator) or_break
		defer free_all(context.temp_allocator)

		if board.data == nil {
			llen := len(line)
			board.data = make([]u8, llen * llen)
			board.back_buffer = make([]u8, llen * llen)
			board.size = llen
		}

		for c in line {
			if c == '@' {
				board.data[i] = 1
			} else {
				board.data[i] = 0
			}
			i += 1
		}
	}

	result: int
	switch part {
	case PART1:
		result = advance_board(&board)
	case PART2:
		for {
			available := advance_board(&board) 
			result += available
			if available == 0 do break
		}
	}
	fmt.printfln("Total rolls available: %v", result)
}

advance_board :: proc(board: ^Board) -> (count: int) {
	for y in 0 ..< board.size {
		for x in 0 ..< board.size {
			if get_board_val(board^, x, y) == 1 {
				if count_neighbours(board^, x, y) < 4 {
					count += 1
				} else {
					board_set(board^, x, y, 1)
				}
			}
		}
	}
	board_swap_clear(board)
	return
}

count_neighbours :: proc(board: Board, x0, y0: int) -> (count: int) {
	for y in y0 - 1 ..= y0 + 1 {
		for x in x0 - 1 ..= x0 + 1 {
			if y < 0 || y >= board.size || x < 0 || x >= board.size {
				continue
			}
			if x == x0 && y == y0 {
				continue
			}
			count += int(get_board_val(board, x, y))
		}
	}
	return
}

get_board_val :: proc(board: Board, x, y: int) -> u8 {
	return board.data[y * board.size + x]
}

board_swap_clear :: proc(board: ^Board) {
	board.data, board.back_buffer = board.back_buffer, board.data
	slice.fill(board.back_buffer, 0)
}

board_set :: proc(board: Board, x, y: int, val: u8) {
	board.back_buffer[y * board.size + x] = val
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

