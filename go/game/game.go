package game

const (
	NumTiles = 9
	UIWidth  = 4
)

type (
	SpriteIndex = uint8
	Position    = int32
	// type Delta should only ever be -1, 0, or 1. When added with
	// a Position, produces another Position.
	Delta = Position
	HP    = uint8
	Level = uint8
)

type State struct {
	player   Player
	tiles    Tiles
	level    Level
	monsters []Monstrous
}

func (s *State) TryMovePlayer(dx, dy Delta) {
	s.player.tryMove(&s.tiles, dx, dy)
}

type Platform interface {
	Sprite(sprite SpriteIndex, x, y Position)
	// Later we can add a Text and a Sound method here
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
