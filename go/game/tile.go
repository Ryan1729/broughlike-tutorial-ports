package game

type Tileish interface {
	tile() *Tile
	dist(tileish Tileish) Distance
	stepOn(p Platform, s *State, monster Monstrous) error
	setEffect(sprite SpriteIndex)
}

type Tile struct {
	monster       Monstrous
	x, y          Position
	sprite        SpriteIndex
	passable      bool
	treasure      bool
	effect        SpriteIndex
	effectCounter counter
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

const (
	effectDuration = 30
)

func (t *Tile) draw(p Platform, shake shake) {
	sprite(p, t.sprite, t.x, t.y, shake)

	if t.treasure {
		sprite(p, 12, t.x, t.y, shake)
	}

	if t.effectCounter.isActive() {
		t.effectCounter.dec()

		spriteWithAlpha(
			p,
			t.effect,
			t.x,
			t.y,
			shake,
			Alpha(float32(t.effectCounter.value)/effectDuration),
		)
	}
}

func (t *Tile) setEffect(sprite SpriteIndex) {
	t.effect = sprite
	t.effectCounter = counter{effectDuration}
}

func (t *Tile) tile() *Tile {
	return t
}

func (t *Tile) stepOn(_ Platform, s *State, monster Monstrous) (err error) {
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

func (t *Floor) stepOn(p Platform, s *State, monster Monstrous) (err error) {
	if _, isPlayer := monster.(*Player); isPlayer && t.treasure {
		s.score++

		if s.score%3 == 0 && s.numSpells < 9 {
			s.numSpells++
			s.player.addSpell(s.spells)
		}

		p.Sound(Treasure)

		t.treasure = false

		m, err := spawnMonster(s)
		if err != nil {
			return err
		}
		s.monsters = append(s.monsters, m)
	}

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

func (t *Exit) stepOn(p Platform, s *State, monster Monstrous) (err error) {
	_, isPlayer := monster.(*Player)

	if isPlayer {
		p.Sound(NewLevel)

		if s.level == numLevels {
			addScore(p, s.score, Won)
			s.state = title
		} else {
			s.level++

			newHP := s.player.hp + 1
			if newHP > maxHP {
				newHP = maxHP
			}

			err = startLevel(s, newHP, nil)
		}
	}

	return
}
