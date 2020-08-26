package game

type (
	SpriteIndex = uint8
	Position    = int32
)

type State struct {
	X, Y Position
}

type Platform interface {
	Sprite(sprite SpriteIndex, x, y Position)
	// Later we can add a Text and a Sound method here
}

func Draw(p Platform, s *State) {
	p.Sprite(0, s.X, s.Y)
}
