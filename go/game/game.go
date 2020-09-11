package game

const (
	NumTiles   = 9
	UIWidth    = 4
	maxHP      = 6
	startingHp = 3
)

const (
	Other KeyType = iota
	Up    KeyType = iota
	Down  KeyType = iota
	Left  KeyType = iota
	Right KeyType = iota
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
	Distance = int8
	// Effectively only takes on the following values:
	// [0, 0.5, 1.0, ..., maxHP - 0.5, maxHP]
	// So we could represent it in a uint8 by interpreting 2 as 1.0 etc., if
	// we wanted to.
	HP              = float32
	Level           = uint8
	SubTilePosition = float32
	KeyType         uint8
	gameState       uint8
)

const (
	title   gameState = iota
	running gameState = iota
	dead    gameState = iota
)

type State struct {
	player       Player
	tiles        Tiles
	monsters     []Monstrous
	spawnRate    counter
	spawnCounter counter
	level        Level
	state        gameState
}

func (s *State) Input(keyType KeyType) error {
	var err error = nil
	switch s.state {
	case title:
		err = startGame(s)
	case dead:
		s.state = title
	case running:
		switch keyType {
		case Up:
			err = s.player.tryMove(s, 0, -1)
		case Left:
			err = s.player.tryMove(s, -1, 0)
		case Down:
			err = s.player.tryMove(s, 0, 1)
		case Right:
			err = s.player.tryMove(s, 1, 0)
		case Other:
			fallthrough
		default:
		}
	}

	return err
}

func startGame(s *State) error {
	s.level = 1

	err := startLevel(s, startingHp)
	if err != nil {
		return err
	}

	s.state = running

	return nil
}

func startLevel(s *State, playerHp HP) error {
	s.spawnRate = counter{15}

	s.spawnCounter = s.spawnRate

	err := generateLevel(s)
	if err != nil {
		return err
	}

	startingTileish, err := s.tiles.randomPassable()
	if err != nil {
		return err
	}

	s.player = *NewPlayerStruct(startingTileish)

	s.player.monster().hp = playerHp

	return nil
}

type Platform interface {
	SubTileSprite(sprite SpriteIndex, x, y SubTilePosition)
	Overlay()
	// Later we can add a Text and a Sound method here
}

func sprite(p Platform, sprite SpriteIndex, x, y Position) {
	p.SubTileSprite(sprite, SubTilePosition(x), SubTilePosition(y))
}

func Draw(p Platform, s *State) {
	drawGameScreen(p, s)

	if s.state == title {
		p.Overlay()
	}
}

func drawGameScreen(p Platform, s *State) {
	if s.monsters == nil {
		return
	}

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

func tick(s *State) error {
	for i := len(s.monsters) - 1; i >= 0; i-- {
		if s.monsters[i].monster().dead {
			// Remove the dead monster
			copy(s.monsters[i:], s.monsters[i+1:])
			s.monsters = s.monsters[:len(s.monsters)-1]
		} else {
			s.monsters[i].update(s)
		}
	}

	if s.player.monster().dead {
		s.state = dead
	}

	s.spawnCounter.dec()
	if !s.spawnCounter.isActive() {
		m, err := spawnMonster(s)
		if err != nil {
			return err
		}
		s.monsters = append(s.monsters, m)

		s.spawnCounter = s.spawnRate
		s.spawnRate.dec()
	}

	return nil
}
