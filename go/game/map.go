package game

import (
	"math/rand"
)

func GenerateLevel(s *State) error {
	err := tryTo("generate map", func() bool {
		tiles, connectedCount := generateTiles()

		randomTile, err := tiles.randomPassable()
		if err != nil {
			return false
		}

		isConnected := connectedCount == len(tiles.getConnected(randomTile))

		if isConnected {
			s.tiles = tiles
		}

		return isConnected
	})
	if err != nil {
		return err
	}

	startingTileish, err := s.tiles.randomPassable()
	if err != nil {
		return err
	}
	startingTile := startingTileish.tile()

	s.X, s.Y = startingTile.x, startingTile.y

	return nil
}

func generateTiles() (tiles Tiles, passableTiles int) {
	var i, j Position
	for j = 0; j < NumTiles; j++ {
		for i = 0; i < NumTiles; i++ {
			if !inBounds(i, j) || rand.Float32() < 0.3 {
				tiles.tiles[i][j] = NewWall(i, j)
			} else {
				tiles.tiles[i][j] = NewFloor(i, j)
				passableTiles++
			}
		}
	}

	return
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

func (ts *Tiles) getNeighbor(tileish Tileish, dx, dy Delta) Tileish {
	tile := tileish.tile()

	return ts.get(tile.x+dx, tile.y+dy)
}

func (ts *Tiles) getAdjacentNeighbors(tileish Tileish) []Tileish {
	return shuffleInPlace([]Tileish{
		ts.getNeighbor(tileish, 0, -1),
		ts.getNeighbor(tileish, 0, 1),
		ts.getNeighbor(tileish, -1, 0),
		ts.getNeighbor(tileish, 1, 0),
	})
}

func (ts *Tiles) getAdjacentPassableNeighbors(tileish Tileish) []Tileish {
	neighbors := ts.getAdjacentNeighbors(tileish)

	return filter(neighbors, func(t Tileish) bool { return t.tile().passable })
}

func (ts *Tiles) randomPassable() (Tileish, error) {
	var tileish Tileish

	err := tryTo("get random passable tile", func() bool {
		x, y := randomRangePosition(0, NumTiles-1), randomRangePosition(0, NumTiles-1)
		tileish = ts.get(x, y)
		tile := tileish.tile()

		return tile.passable && tile.monster == nil
	})
	if err != nil {
		return nil, err
	}

	return tileish, nil
}

func (ts *Tiles) getConnected(tileish Tileish) []Tileish {
	connected := []Tileish{tileish}
	frontier := []Tileish{tileish}

	notAlreadyInConnected := func(t Tileish) bool {
		for _, v := range connected {
			if v == t {
				return false
			}
		}

		return true
	}

	for len(frontier) > 0 {
		lastIndex := len(frontier) - 1

		neighbors := filter(
			ts.getAdjacentPassableNeighbors(frontier[lastIndex]),
			notAlreadyInConnected,
		)
		frontier = frontier[0:lastIndex]

		connected = append(connected, neighbors...)
		frontier = append(frontier, neighbors...)
	}

	return connected
}

// Mutates the passed in slice, but also returns it to be convenient.
func shuffleInPlace(slice []Tileish) []Tileish {
	length := len(slice)
	for i := 1; i < length; i++ {
		r := randomRangeInt(0, i)
		slice[i], slice[r] = slice[r], slice[i]
	}

	return slice
}

func filter(slice []Tileish, predicate func(Tileish) bool) []Tileish {
	output := make([]Tileish, 0, len(slice))

	for _, tileish := range slice {
		if predicate(tileish) {
			output = append(output, tileish)
		}
	}

	return output
}
