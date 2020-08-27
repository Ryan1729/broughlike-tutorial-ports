package game

import (
	"math/rand"
)

func GenerateLevel(s *State) {
	s.tiles = generateTiles()
}

func generateTiles() Tiles {
	var tiles [NumTiles][NumTiles]Tileish
	var i, j Position
	for j = 0; j < NumTiles; j++ {
		for i = 0; i < NumTiles; i++ {
			if !inBounds(i, j) || rand.Float32() < 0.3 {
				tiles[i][j] = NewWall(i, j)
			} else {
				tiles[i][j] = NewFloor(i, j)
			}
		}
	}

	return Tiles{tiles}
}

type Tiles struct {
	tiles [NumTiles][NumTiles]Tileish
}
