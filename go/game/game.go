package game

const (
	NumTiles = 9
	UIWidth  = 4
)

type (
	SpriteIndex = uint8
	Position    = int32
)

type State struct {
	X, Y  Position
	tiles Tiles
}

type Platform interface {
	Sprite(sprite SpriteIndex, x, y Position)
	// Later we can add a Text and a Sound method here
}

func Draw(p Platform, s *State) {
	p.Sprite(0, s.X, s.Y)
}
