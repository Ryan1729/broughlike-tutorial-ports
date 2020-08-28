package game

import (
	"math/rand"
)

func GenerateLevel(s *State) error {
	s.tiles = generateTiles()

	startingTileish, err := s.tiles.randomPassable()
	if err != nil {
		return err
	}
	startingTile := startingTileish.tile()

	s.X, s.Y = startingTile.x, startingTile.y

	return nil
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

func inBounds(x, y Position) bool {
	return x > 0 && y > 0 && x < NumTiles-1 && y < NumTiles-1
}

type Tiles struct {
	tiles [NumTiles][NumTiles]Tileish
}

func (ts *Tiles) get(x, y Position) Tileish {
	if inBounds(x, y) {
		return ts.tiles[x][y]
	}

	return NewWall(x, y)
}

func (ts *Tiles) randomPassable() (Tileish, error) {
	var tileish Tileish

	err := tryTo("get random passable tile", func() bool {
		x, y := randomRange(0, NumTiles-1), randomRange(0, NumTiles-1)
		tileish = ts.get(x, y)
		tile := tileish.tile()

		return tile.passable && tile.monster == nil
	})
	if err != nil {
		return nil, err
	}

	return tileish, nil
}
