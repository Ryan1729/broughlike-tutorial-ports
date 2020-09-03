package game

const (
	NumTiles = 9
	UIWidth  = 4
)

type (
	SpriteIndex = uint8
	// type Position is the one-dimensional position of something on the map
	// The type should only ever hold values inside [0, Numtiles - 1].
	Position = uint8
	// type Delta should only ever be -1, 0, or 1. When added with
	// a Position, produces another Position.
	Delta = int8
	// type Distance is the manhattan distance from (Position, Position) to
	// another. At most this can be NumTiles * 2.
	Distance        = int8
	HP              = uint8
	Level           = uint8
	SubTilePosition = float32
)

type State struct {
	player   Player
	tiles    Tiles
	level    Level
	monsters []Monstrous
}

func (s *State) TryMovePlayer(dx, dy Delta) {
	s.player.tryMove(s, dx, dy)
}

type Platform interface {
	SubTileSprite(sprite SpriteIndex, x, y SubTilePosition)
	// Later we can add a Text and a Sound method here
}

func sprite(p Platform, sprite SpriteIndex, x, y Position) {
	p.SubTileSprite(sprite, SubTilePosition(x), SubTilePosition(y))
}

func Draw(p Platform, s *State) {
	var i, j Position
	for j = 0; j < NumTiles; j++ {
		for i = 0; i < NumTiles; i++ {
			s.tiles.get(i, j).tile().draw(p)
		}
	}

	for _, m := range s.monsters {
		m.draw(p)
	}

	s.player.draw(p)
}

func tick(s *State) {
	for i := len(s.monsters) - 1; i >= 0; i-- {
		if s.monsters[i].monster().dead {
			// Remove the dead monster
			copy(s.monsters[i:], s.monsters[i+1:])
			s.monsters = s.monsters[:len(s.monsters)-1]
		} else {
			s.monsters[i].update(s)
		}
	}
}
