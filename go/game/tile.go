package game

type Tileish interface {
	tile() *Tile
	dist(tileish Tileish) Distance
	stepOn(s *State, monster Monstrous) error
}

type Tile struct {
	monster  Monstrous
	x, y     Position
	sprite   SpriteIndex
	passable bool
	treasure bool
}

func NewTile(sprite SpriteIndex, x, y Position, passable bool) *Tile {
	return &Tile{
		x: x, y: y,
		sprite:   sprite,
		passable: passable,
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

	if t.treasure {
		sprite(p, 12, t.x, t.y)
	}
}

func (t *Tile) tile() *Tile {
	return t
}

func (t *Tile) stepOn(s *State, monster Monstrous) (err error) {
	// Empty default implementation
	return
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

func (t *Floor) stepOn(s *State, monster Monstrous) (err error) {
	// Reminder: complete
	return
}

type Wall struct {
	*Tile
}

func NewWall(x, y Position) Tileish {
	return &Wall{
		Tile: NewTile(3, x, y, false),
	}
}

type Exit struct {
	*Tile
}

func NewExit(x, y Position) Tileish {
	return &Exit{
		Tile: NewTile(11, x, y, true),
	}
}

func (t *Exit) stepOn(s *State, monster Monstrous) (err error) {
	_, isPlayer := monster.(*Player)

	println("(t *Exit) stepOn isPlayer: ", isPlayer)

	if isPlayer {
		if s.level == numLevels {
			s.state = title
		} else {
			s.level++

			newHP := s.player.hp + 1
			if newHP > maxHP {
				newHP = maxHP
			}

			err = startLevel(s, newHP)
		}
	}

	return
}
