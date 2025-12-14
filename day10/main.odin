package day10

import "core:fmt"
import "core:math"
import "core:math/bits"
import "core:os"
import "core:strconv"
import "core:strings"

PART1 :: 1
PART2 :: 2

Device :: struct {
	indicators: u16,
	masks:      [dynamic]u16,
	joltages:   [dynamic]int,
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
	file, _ := os.read_entire_file(os.args[1])
	str := string(file)
	defer delete(file)

	devices := make([dynamic]Device)
	defer delete(devices)

	for line in strings.split_lines_iterator(&str) {
		append(&devices, parse_device(line, context.temp_allocator))
	}

	result: int
	switch part {
	case PART1:
		for device in devices {
			result += part1(device)
		}
	case PART2:
		for device in devices {
			result += part2(device)
		}
	}
	fmt.printfln("Total: %v", result)
}

part2 :: proc(device: Device) -> int {
	lengths: [10]int
	walk: [13]int

	size := len(device.masks)
	j_size := len(device.joltages)

	for mask, i in device.masks {
		min_val := 1 << 16
		for jolt, j in device.joltages {
			if mask & (1 << uint(j)) != 0 {
				min_val = min(jolt, min_val)
			}
		}
		lengths[i] = min_val + 1
	}
	fmt.printfln("Min vals: %v", lengths[:size])


	min_presses := 1 << 16

	loop: for {
		res: [10]int // = len(device.joltages)

		for k, i in walk[:size] {
			for x := 0; x < j_size; x += 1 {
				if device.masks[i] & (1 << uint(x)) > 0 {
					res[x] += k
				}
			}
		}

		//fmt.printfln(" %v %v", walk[:size], res[:j_size])

		equals := true
		for i in 0 ..< j_size {
			if device.joltages[i] != res[i] {
				equals = false
				break
			}
		}
		//if slice.equal(device.joltages[:], res[:j_size]) {
		if equals {
			min_presses = min(min_presses, math.sum(walk[:size]))
			//fmt.printfln("new min %v", walk[:size])
		}

		{
			whoIncrement: int
			for whoIncrement < size {
				if walk[whoIncrement] < lengths[whoIncrement] - 1 {
					walk[whoIncrement] += 1
					continue loop
				} else {
					walk[whoIncrement] = 0
					whoIncrement += 1
				}
			}
			break
		}
	}

	return min_presses
}

part1 :: proc(device: Device) -> int {
	min_presses := len(device.masks)
	mask_configurations := 1 << uint(len(device.masks))
	for combination in 1 ..= mask_configurations {
		final_mask: u16
		for mask, i in device.masks {
			if combination & (1 << uint(i)) != 0 {
				final_mask ~= mask
			}
		}
		if final_mask == device.indicators {
			min_presses = min(min_presses, int(bits.count_ones(combination)))
		}
	}
	return min_presses
}

parse_device :: proc(str: string, allocator := context.allocator) -> (d: Device) {
	parts := str
	d.masks = make([dynamic]u16, allocator)
	d.joltages = make([dynamic]int, allocator)
	for group in strings.split_by_byte_iterator(&parts, ' ') {
		switch group[0] {
		case '[':
			indicators := group[1:len(group) - 1]
			for val, i in indicators {
				if val == '#' {
					d.indicators ~= 1 << u16(i)
				}
			}
		case '(':
			csv := group[1:len(group) - 1]
			mask: u16
			for val in strings.split_by_byte_iterator(&csv, ',') {
				mask ~= 1 << (strconv.parse_uint(val) or_else panic("Cannot parse input"))
			}
			append(&d.masks, mask)
		case '{':
			csv := group[1:len(group) - 1]
			for val in strings.split_by_byte_iterator(&csv, ',') {
				append(&d.joltages, strconv.parse_int(val) or_else panic("Cannot parse input"))
			}
		}
	}
	return d
}

