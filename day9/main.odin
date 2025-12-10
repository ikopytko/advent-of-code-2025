package day9

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

PART1 :: 1
PART2 :: 2

AABB :: struct {
	min: [2]int,
	max: [2]int,
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

	coords := make([dynamic][2]int)
	defer delete(coords)

	for line in strings.split_lines_iterator(&str) {
		xy := line
		coord: [2]int
		i: int
		for c in strings.split_by_byte_iterator(&xy, ',') {
			coord[i] = strconv.parse_int(c) or_else panic("Cannot parse input")
			i += 1
		}
		append(&coords, coord)
	}

	result: int
	switch part {
	case PART1:
		result = part1(coords[:])
	case PART2:
		result = part2(coords[:])
	}
	fmt.printfln("Total: %v", result)
}

part1 :: proc(coords: [][2]int) -> int {
	size := len(coords)
	max_area: int
	for a in 0 ..< size {
		for b in 0 ..< size {
			rect_area := area(coords[a], coords[b])
			max_area = max(rect_area, max_area)
		}
	}
	return max_area
}

part2 :: proc(coords: [][2]int) -> int {
	size := len(coords)
	max_area: int
	lines := make([dynamic]AABB, size)
	defer delete(lines)
	for i in 0 ..< size do append(&lines, make_aabb(coords[i], coords[(i + 1) % size]))

	for a in 0 ..< size - 1 {
		next: for b in a + 1 ..< size {
			aabb := make_aabb(coords[a], coords[b])
			for line in lines {
				if intersect(aabb, line) do continue next
			}

			rect_area := area(coords[a], coords[b])
			max_area = max(rect_area, max_area)
		}
	}
	return max_area
}

intersect :: proc(box, line: AABB) -> bool {
	if line.min.x == line.max.x {
		if box.min.x < line.min.x && line.min.x < box.max.x {
			min_y, max_y := max(box.min.y, line.min.y), min(box.max.y, line.max.y)
			if min_y < max_y do return true
		}
	} else {
		if box.min.y < line.min.y && line.min.y < box.max.y {
			min_x, max_x := max(box.min.x, line.min.x), min(box.max.x, line.max.x)
			if min_x < max_x do return true
		}
	}
	return false
}

make_aabb :: proc(a, b: [2]int) -> AABB {
	return AABB{{min(a.x, b.x), min(a.y, b.y)}, {max(a.x, b.x), max(a.y, b.y)}}
}

area :: proc(a, b: [2]int) -> (area: int) {
	return (abs(a.x - b.x) + 1) * (abs(a.y - b.y) + 1)
}

