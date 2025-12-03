package day3

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

	total_rating: i64

	for {
		line := read_line(&r, context.temp_allocator) or_break
		defer free_all(context.temp_allocator)

		rating: i64
		switch part {
		case PART1:
			rating = compute_rating(line) // compute_rating_2(line, 2)
		case PART2:
			rating = compute_rating_2(line, 12)
		}

		total_rating += rating
		fmt.printfln("Line %v: %v", line, rating)
	}

	fmt.printfln("Total rating: %v", total_rating)
}

compute_rating :: proc(line: string) -> (rating: i64) {
	// 2 passes, simple way
	max1, max1_pos, max2: int
	for c, i in line[:len(line) - 1] {
		num := int(c - '0')
		if num > max1 {
			max1 = num
			max1_pos = i
		}
	}

	for c in line[max1_pos + 1:] {
		num := int(c - '0')
		if num > max2 {
			max2 = num
		}
	}
	return i64(max1 * 10 + max2)
}

compute_rating_2 :: proc(line: string, $N: int) -> (rating: i64) {
	x: [N]int
	llen := len(line)

	// initial fill with last N digits
	for pos, i in llen - N ..< llen {
		x[i] = int(line[pos] - '0')
	}

	// progressively shift each position as far as possible / partial "bubble sort"
	last_left := 0
	for digit in 0 ..< N {
		most_left := last_left
		for pos := llen + digit - N; pos >= most_left; pos -= 1 {
			num := int(line[pos] - '0')
			if num >= x[digit] {
				x[digit] = num
				last_left = pos
			}
		}
		last_left += 1
	}

	number: i64 = 0
	for digit in x {
		number += i64(digit)
		number *= 10
	}

	return number / 10
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
