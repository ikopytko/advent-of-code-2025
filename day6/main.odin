package day6

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

PART1 :: 1
PART2 :: 2

Mode :: enum {
	ReadMode,
	Add,
	Mul,
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

	// top level allocations, OS will handle it
	file, _ := os.read_entire_file(os.args[1])
	lines := strings.split_lines(string(file))

	result: int
	switch part {
	case PART1:
		result = part1(lines[:len(lines) - 1])
	case PART2:
		result = part2(lines[:len(lines) - 1])
	}
	fmt.printfln("Total: %v", result)
}

part2 :: proc(lines: []string) -> (result: int) {
	operator_row := len(lines) - 1
	num_index: int
	buffer: [10]int

	for col := len(lines[0]) - 1; col >= 0; col -= 1 {
		power: int

		for row := len(lines) - 2; row >= 0; row -= 1 {
			value := lines[row][col]

			if value == ' ' do continue
			number := buffer[num_index]
			number += int(value - '0') * pow(10, power)
			buffer[num_index] = number
			power += 1
		}
		num_index += 1

		operator := lines[operator_row][col]
		if operator != ' ' {
			switch operator {
			case '+':
				result += add(buffer[:], num_index)
			case '*':
				result += mul(buffer[:], num_index)
			}
			slice.zero(buffer[:])
			num_index = 0
			col -= 1
		}
	}
	return
}

add :: proc(arr: []int, len: int) -> int {
	result := 0
	for i in 0 ..< len do result += arr[i]
	return result
}

mul :: proc(arr: []int, len: int) -> int {
	result := arr[0]
	for i in 1 ..< len do result *= arr[i]
	return result
}

pow :: proc(x, power: int) -> int {
	result := 1
	for _ in 0 ..< power do result *= x
	return result
}

part1 :: proc(lines: []string) -> (result: int) {
	loop: for {
		mode: Mode
		buffer: int
		for i := len(lines) - 1; i >= 0; i -= 1 {
			value := split_by_space_iterator(&lines[i]) or_break loop
			switch mode {
			case .ReadMode:
				if value[0] == '+' {
					mode = .Add
				} else if value[0] == '*' {
					mode = .Mul
					buffer = 1
				} else {
					panic("Unknown operator")
				}
				continue
			case .Add:
				buffer += strconv.parse_int(value) or_else panic("Value cannot be parsed")
			case .Mul:
				buffer *= strconv.parse_int(value) or_else panic("Value cannot be parsed")
			}
		}
		result += buffer
	}
	return
}

split_by_space_iterator :: proc(s: ^string) -> (res: string, ok: bool) {
	for {
		res, ok = strings.split_by_byte_iterator(s, ' ')
		if len(res) > 0 do return
		if !ok do return
	}
}

