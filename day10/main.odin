package day10

import "core:hash"
import "core:time"
import "core:fmt"
import "core:math"
import "core:math/bits"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

PART1 :: 1
PART2 :: 2

Device :: struct {
	indicators: u16,
	masks:      [dynamic]u16,
	joltages:   [dynamic]int,
	patterns:   map[u16][dynamic]u16,
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
		append(&devices, parse_device(line, context.allocator))
	}
	
	start_time := time.tick_now()

	result: int
	switch part {
	case PART1:
		for device in devices {
			result += part1(device)
		}
	case PART2:
		for device in devices {
			//result += part2(device)
			result += solve_optimized(device)
		}
	}
	fmt.printfln("Total: %v in %vms", result, time.duration_milliseconds(time.tick_since(start_time)))
}

solve_optimized :: proc(device: Device) -> int {
	joltages: [10]int
	for i in 0 ..< len(device.joltages) {
		joltages[i] = device.joltages[i]
	}
	
	cache := make(map[u32]int)
	defer delete(cache)

	return get_min_presses(device, joltages, &cache) or_else panic("Cannot calculate result")

	get_min_presses :: proc(device: Device, target_arr: [10]int, cache: ^map[u32]int) -> (result: int, ok: bool) {
		target_arr := target_arr
		target := target_arr[:len(device.joltages)]
		if slice.all_of(target, 0) do return 0, true
		if slice.any_of_proc(target, proc(v: int) -> bool {return v < 0}) do return 0, false
		
		hval := hash.murmur32(slice.reinterpret([]byte, target_arr[:]))
		if hval in cache do return cache[hval]
		

		target_pattern: u16
		for val, i in target {
			if val % 2 == 1 {
				target_pattern |= (1 << uint(i))
			}
		}
		
		if !(target_pattern in device.patterns) do return

		result = 1e9

		loop: for pattern in device.patterns[target_pattern] {
			target_after_arr := target_arr
			target_after := target_after_arr[:len(device.joltages)]

			// iterate pattern bits
			// if bit is set get mask by pattern bit idx
			// iterate mask bits
			// if bit set decr target at mask bit idx
			for mask_idx in 0 ..< len(device.masks) {
				if pattern & (1 << uint(mask_idx)) != 0 {
					for &jolt, j in target_after {
						if device.masks[mask_idx] & (1 << uint(j)) != 0 {
							jolt -= 1
						}
					}
				}
			}

			if slice.any_of_proc(target_after[:], proc(v: int) -> bool {return v % 2 != 0}) do continue

			half_target: [10]int
			for i in 0 ..< len(target_after) {
				half_target[i] = target_after[i] / 2
			}

			presses := get_min_presses(device, half_target, cache) or_continue
			result = min(result, int(bits.count_ones(pattern)) + 2 * presses)
			ok = true
		}
		
		cache[hval] = result
		return
	}
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
	precompute_patterns(&d)
	return d
}

precompute_patterns :: proc(device: ^Device) {
	device.patterns = make(map[u16][dynamic]u16)

	mask_configurations := 1 << u16(len(device.masks))
	for combination in 0 ..< mask_configurations {
		final_mask: u16
		for mask, i in device.masks {
			if combination & (1 << uint(i)) != 0 {
				final_mask ~= mask
			}
		}

		if !(final_mask in device.patterns) {
			device.patterns[final_mask] = make([dynamic]u16)
		}

		append(&device.patterns[final_mask], u16(combination))
	}
}

