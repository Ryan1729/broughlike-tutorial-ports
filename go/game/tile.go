package game

type Tileish interface {
	tile() *Tile
	dist(tileish Tileish) Distance
	// We can add a StepOn method here later
}

type Tile struct {
	x, y     Position
	sprite   SpriteIndex
	passable bool
	monster  Monstrous
}

func NewTile(sprite SpriteIndex, x, y Position, passable bool) *Tile {
	return &Tile{
		x, y,
		sprite,
		passable,
		nil,
	}
}

func (t *Tile) dist(tileish Tileish) Distance {
	tile := tileish.tile()

	return abs(Distance(t.x)-Distance(tile.x)) + abs(Distance(t.y)-Distance(tile.y))
}

// passes the minimum value (-2^N) through unchanged.
func abs(d Distance) Distance {
	if d < 0 {
		return -d
	}

	return d
}

func (t *Tile) draw(p Platform) {
	sprite(p, t.sprite, t.x, t.y)
}

func (t *Tile) tile() *Tile {
	return t
}

type TileMaker = func(x, y Position) Tileish

type Floor struct {
	*Tile
}

func NewFloor(x, y Position) Tileish {
	return &Floor{
		Tile: NewTile(2, x, y, true),
	}
}

type Wall struct {
	*Tile
}

func NewWall(x, y Position) Tileish {
	return &Wall{
		Tile: NewTile(3, x, y, false),
	}
}
