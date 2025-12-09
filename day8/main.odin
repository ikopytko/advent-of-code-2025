package day8

import "core:fmt"
import "core:math/linalg"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

PART1 :: 1
PART2 :: 2

Weight :: struct {
	points: [2]int,
	weight: int,
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

	coords := make([dynamic][3]int)
	defer delete(coords)

	for line in strings.split_lines_iterator(&str) {
		xyz := line
		coord: [3]int
		i: int
		for c in strings.split_by_byte_iterator(&xyz, ',') {
			coord[i] = strconv.parse_int(c) or_else panic("Cannot parse input")
			i += 1
		}
		append(&coords, coord)
	}

	size := len(coords)
	// lower triangle size
	weights := make([dynamic]Weight, size * (size - 1) / 2)
	for a in 0 ..< size {
		for b in 0 ..< size - 1 {
			// index in lower triangle
			i := (a * (a - 1)) / 2 + b
			weights[i] = {{a, b}, linalg.length2(coords[b] - coords[a])}
		}
	}

	slice.sort_by_key(weights[:], proc(w: Weight) -> int {return w.weight})

	result: int
	switch part {
	case PART1:
		result = part1(weights[:], size)
	case PART2:
			points := part2(weights[:], size)
			result = coords[points.x].x * coords[points.y].x
	}
	fmt.printfln("Total: %v", result)
}

part2 :: proc(weights: []Weight, size: int) -> [2]int {
	connections := make([dynamic]int, size)
	circuits_count: int

	islands := size
	for i in 0 ..< len(weights) {
		points := weights[i].points
		islands -= 1
		if connections[points.x] == 0 && connections[points.y] == 0 {
			circuits_count += 1
			connections[points.x] = circuits_count
			connections[points.y] = circuits_count
		} else if connections[points.x] == connections[points.y] {
			islands += 1
		} else if connections[points.x] == 0 {
			connections[points.x] = connections[points.y]
		} else if connections[points.y] == 0 {
			connections[points.y] = connections[points.x]
		} else {
			merge_circuits(connections[:], connections[points.y], connections[points.x])
		}
		if islands == 1 {
			return points
		} 
	}
	panic("unreachable")
}

part1 :: proc(weights: []Weight, size: int) -> int {
	connections := make([dynamic]int, size)
	circuits := make(map[int]int)
	circuits_count: int
	N := 10 if size == 20 else 1000
	for i in 0 ..< N {
		points := weights[i].points
		if connections[points.x] == 0 && connections[points.y] == 0 {
			circuits_count += 1
			connections[points.x] = circuits_count
			connections[points.y] = circuits_count
			circuits[circuits_count] = 2
		} else if connections[points.x] == connections[points.y] {
			continue
		} else if connections[points.x] == 0 {
			connections[points.x] = connections[points.y]
			circuits[connections[points.x]] += 1
		} else if connections[points.y] == 0 {
			connections[points.y] = connections[points.x]
			circuits[connections[points.x]] += 1
		} else {
			circuits[connections[points.x]] += circuits[connections[points.y]]
			delete_key(&circuits, connections[points.y])
			merge_circuits(connections[:], connections[points.y], connections[points.x])
		}
	}
	circuits_cap, _ := slice.map_values(circuits)
	slice.reverse_sort(circuits_cap[:])
	result := circuits_cap[0] * circuits_cap[1] * circuits_cap[2]
	return result
}

merge_circuits :: proc(coords: []int, souce, dest: int) {
	for &coord in coords {
		if coord == souce {
			coord = dest
		}
	}
}

