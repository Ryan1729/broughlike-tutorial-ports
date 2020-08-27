package game

type Tileish interface {
	// We can add a StepOn method here later
}

type Tile struct {
	x, y     Position
	sprite   SpriteIndex
	passable bool
}

func NewTile(sprite SpriteIndex, x, y Position, passable bool) Tile {
	return Tile{
		x, y,
		sprite,
		passable,
	}
}

func (t *Tile) draw(p Platform) {
	p.Sprite(t.sprite, t.x, t.y)
}

type Floor struct {
	Tile
}

func NewFloor(x, y Position) Floor {
	return Floor{
		Tile: NewTile(2, x, y, true),
	}
}

type Wall struct {
	Tile
}

func NewWall(x, y Position) Wall {
	return Wall{
		Tile: NewTile(3, x, y, false),
	}
}
