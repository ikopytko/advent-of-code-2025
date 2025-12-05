package day5

import "core:fmt"
import "core:os"
import "core:sort"
import "core:strconv"
import "core:strings"

PART1 :: 1
PART2 :: 2

Range :: struct {
	from: int,
	to:   int,
}

Stages :: enum {
	ReadRanges,
	ReadIds,
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

	ranges := make([dynamic]Range)
	defer delete(ranges)

	stage := Stages.ReadRanges
	result: int

	for line in strings.split_lines_iterator(&str) {
		if len(line) == 0 {
			if stage == .ReadRanges {
				stage = .ReadIds
				if part == PART2 do break
			} else {
				break
			}
		}

		switch stage {
		case .ReadRanges:
			append(&ranges, parse_range(line) or_break)
		case .ReadIds:
			num := strconv.parse_int(line) or_break
			for range in ranges {
				if num >= range.from && num <= range.to {
					result += 1
					break
				}
			}
		}
	}

	switch part {
	case PART1:
	case PART2:
		merged_ranges := merge_ranges(ranges[:])
		result = sum_ranges(merged_ranges)
	}
	fmt.printfln("Total: %v", result)
}

parse_range :: proc(str: string) -> (range: Range, ok: bool) {
	hyphen := strings.index_rune(str, '-')
	from := strconv.parse_int(str[:hyphen]) or_return
	to := strconv.parse_int(str[hyphen + 1:]) or_return
	return Range{from, to}, true
}

merge_ranges :: proc(ranges: []Range) -> []Range {
	sort.quick_sort_proc(ranges, proc(a, b: Range) -> int {return a.from - b.from})

	new_tail: int
	for range, i in ranges {
		if i == 0 {
			continue
		}
		prev_range := &ranges[new_tail]
		if prev_range.to < range.from {
			new_tail += 1
			ranges[i], ranges[new_tail] = ranges[new_tail], ranges[i]
		} else {
			prev_range.to = max(range.to, prev_range.to)
		}
	}
	return ranges[:new_tail + 1]
}

sum_ranges :: proc(ranges: []Range) -> (result: int) {
	for range in ranges {
		result += range.to - range.from + 1
	}
	return
}

