package day1

import "core:fmt"
import "core:os"
import "core:strconv"
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

	file, _ := os.read_entire_file(os.args[1])
	str := string(file)
	defer delete(file)

	total_invalid_sum: i64 = 0
	for range in strings.split_by_byte_iterator(&str, ',') {
		start, end := split_range(strings.trim_space(range)) or_break

		invalid_sum: i64
		switch part {
		case PART1:
			invalid_sum = count_invalid_numbers(start, end)
		case PART2:
			invalid_sum = count_invalid_numbers_2(start, end)
		}
		total_invalid_sum += invalid_sum
	}

	fmt.printfln("Invalid ids: %v", total_invalid_sum)
}

count_invalid_numbers_2 :: proc(start, end: int) -> i64 {
	invalid_count: i64 = 0
	for num in start ..= end {
		str := fmt.tprint(num) // good enough
		digits := len(str)
		defer free_all(context.temp_allocator)
		combination: for div in 1 ..= int(f32(digits) / 2) {
			if digits % div != 0 do continue

			for i := div; i < digits; i += div {
				for j := 0; j < div; j += 1 {
					if str[i + j] != str[i + j - div] {
						continue combination
					}
				}
			}

			//fmt.printfln("%v-%v : %v", start, end, num)
			invalid_count += cast(i64)num
			break combination
		}

	}
	return invalid_count
}

count_invalid_numbers :: proc(start, end: int) -> i64 {
	invalid_count: i64 = 0
	for num in start ..= end {
		digits := digits(num)
		if digits % 2 != 0 do continue

		first_half, second_half: int
		pos := 0
		for id := num; id != 0; id /= 10 {
			reminder := id % 10

			if pos < digits / 2 {
				first_half += reminder
				first_half *= 10
			} else {
				second_half += reminder
				second_half *= 10
			}

			pos += 1
		}
		if first_half == second_half {
			//fmt.printfln("%v-%v : %v", start, end, num)
			invalid_count += cast(i64)num
		}
	}
	return invalid_count
}

digits :: proc(n: int) -> int {
	digits := 1
	base :: 10
	for power := 1; n / power >= base; power *= base {
		digits += 1
	}
	return digits
}

split_range :: proc(str: string) -> (start, end: int, ok: bool) {
	hyphen := strings.index_byte(str, '-')
	start = strconv.parse_int(str[:hyphen]) or_return
	end = strconv.parse_int(str[hyphen + 1:]) or_return
	return start, end, true
}
