package game

import (
	"math"
	"sort"
	"strconv"
)

const (
	TitleString = "BROUGH-LANG"
	NumTiles    = 9
	UIWidth     = 4
	// The game requires that tiles can be broken up into at least this many
	// increments, but if tiles are larger than this many pixels across,
	// that should be fine.
	SubTileUnit               = 16
	OneOverSubTileUnit        = 1.0 / SubTileUnit
	tileCenter                = SubTileUnit * NumTiles / 2
	scoreListSpacing          = 6.0 * OneOverSubTileUnit
	maxHP                     = 6
	startingHp                = 3
	numLevels                 = 6
	aqua               Colour = 0xffffff00
	violet             Colour = 0xffee82ee
	white              Colour = 0xffffffff
)

const (
	Other KeyType = iota
	Up    KeyType = iota
	Down  KeyType = iota
	Left  KeyType = iota
	Right KeyType = iota
)

const (
	Lost WonOrLost = false
	Won  WonOrLost = true
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
	HP    = float32
	Level = uint8
	// SubTilePosition is the one-dimensional position of something on the
	// map, but unlike Position, it can hold values of the form
	// k * OneOverSubTileUnit where k is in the range
	// [0, (Numtiles - 1) * SubTileUnit], AKA the range [
	//     0,
	//     OneOverSubTileUnit,
	//     2 * OneOverSubTileUnit,
	//     3 * OneOverSubTileUnit,
	//     ...,
	//     (Numtiles - 1) - OneOverSubTileUnit,
	//     (Numtiles - 1)
	// ]
	// For any given position p, SubTilePosition(p) has the same meaning.
	SubTilePosition = float32
	KeyType         uint8
	gameState       uint8
	Points          uint64
	Run             uint64
	WonOrLost       bool
	Colour          uint32
)

type Score struct {
	Score      Points
	Run        Run
	TotalScore Points
	Active     WonOrLost
}

const (
	title   gameState = iota
	running gameState = iota
	dead    gameState = iota
)

type shake struct {
	amount counter
	x      Position
	y      Position
}

type State struct {
	player       Player
	tiles        Tiles
	monsters     []Monstrous
	shake        shake
	spawnRate    counter
	spawnCounter counter
	level        Level
	state        gameState
	score        Points
}

func (s *State) Input(p Platform, keyType KeyType) error {
	var err error = nil
	switch s.state {
	case title:
		err = startGame(s)
	case dead:
		s.state = title
	case running:
		switch keyType {
		case Up:
			err = s.player.tryMove(p, s, 0, -1)
		case Left:
			err = s.player.tryMove(p, s, -1, 0)
		case Down:
			err = s.player.tryMove(p, s, 0, 1)
		case Right:
			err = s.player.tryMove(p, s, 1, 0)
		case Other:
			fallthrough
		default:
		}
	}

	return err
}

func startGame(s *State) error {
	s.level = 1
	s.score = 0

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

	exitTileish, err := s.tiles.randomPassable()
	if err != nil {
		return err
	}

	s.tiles.replace(exitTileish, NewExit)

	return nil
}

type TextSize uint8

// Any Platform interface implementations only needs to handle these values for
// TextSize.
const (
	UI        TextSize = iota
	Title     TextSize = iota
	ScoreList TextSize = iota
)

type TextJustification uint8

// Any Platform interface implementations only needs to handle these values for
// TextJustification.
const (
	Plain    TextJustification = iota
	Centered TextJustification = iota
)

type Platform interface {
	SubTileSprite(sprite SpriteIndex, x, y, shakeX, shakeY SubTilePosition)
	Overlay()
	Text(text string,
		size TextSize,
		justification TextJustification,
		textY SubTilePosition,
		color Colour,
	)
	GetScores() []Score
	SaveScores(scores []Score)
	// Later we can add a Sound method here
}

func sprite(p Platform, sprite SpriteIndex, x, y Position, shake shake) {
	p.SubTileSprite(
		sprite,
		SubTilePosition(x),
		SubTilePosition(y),
		SubTilePosition(shake.x),
		SubTilePosition(shake.y),
	)
}

func Draw(p Platform, s *State) {
	drawGameScreen(p, s)

	if s.state == title {
		p.Overlay()
		p.Text(TitleString, Title, Centered, tileCenter-SubTileUnit, white)

		drawScores(p)
	}
}

func drawScores(p Platform) {
	scores := p.GetScores()
	length := len(scores)
	if length > 0 {
		p.Text(
			rightPad("RUN", "SCORE", "TOTAL"),
			ScoreList,
			Centered,
			tileCenter,
			white,
		)

		var newestScore Score
		{
			// This block relies on length > 0
			lastIndex := length - 1
			newestScore = scores[lastIndex]
			scores = scores[:lastIndex]
		}

		sort.Slice(scores, func(aIndex, bIndex int) bool {
			return scores[aIndex].TotalScore > scores[bIndex].TotalScore
		})

		scores = append([]Score{newestScore}, scores...)

		displayed := length
		if displayed > 10 {
			displayed = 10
		}

		for i := 0; i < displayed; i++ {
			scoreText := rightPad(
				strconv.FormatUint(uint64(scores[i].Run), 10),
				strconv.FormatUint(uint64(scores[i].Score), 10),
				strconv.FormatUint(uint64(scores[i].TotalScore), 10),
			)

			colour := violet
			if i == 0 {
				colour = aqua
			}

			p.Text(
				scoreText,
				ScoreList,
				Centered,
				tileCenter+SubTilePosition(i+1)*(SubTileUnit*scoreListSpacing),
				colour,
			)
		}
	}
}

func drawGameScreen(p Platform, s *State) {
	if s.monsters == nil {
		return
	}

	screenshake(&s.shake)

	var i, j Position
	for j = 0; j < NumTiles; j++ {
		for i = 0; i < NumTiles; i++ {
			s.tiles.get(i, j).tile().draw(p, s.shake)
		}
	}

	for _, m := range s.monsters {
		m.draw(p, s.shake)
	}

	s.player.draw(p, s.shake)

	p.Text("Level: "+strconv.FormatUint(uint64(s.level), 10), UI, Plain, SubTileUnit/4, violet)
	p.Text("Score: "+strconv.FormatUint(uint64(s.score), 10), UI, Plain, SubTileUnit*3/4, violet)
}

func screenshake(shake *shake) {
	shake.amount.dec()

	shakeAmount := shake.amount.value
	shakeAngle := randomFloat() * math.Pi * 2
	shake.x = Position(
		math.Round(math.Cos(shakeAngle) * float64(shakeAmount)),
	)
	shake.y = Position(
		math.Round(math.Sin(shakeAngle) * float64(shakeAmount)),
	)
}

func addScore(p Platform, score Points, wonOrLost WonOrLost) {
	scores := p.GetScores()
	scoreStruct := Score{
		Score:      score,
		Run:        1,
		TotalScore: score,
		Active:     wonOrLost,
	}
	var lastScore *Score
	{
		lastIndex := len(scores) - 1
		if lastIndex >= 0 {
			lastScore = &scores[lastIndex]
			scores = scores[:lastIndex]
		}
	}

	if lastScore != nil {
		if lastScore.Active {
			scoreStruct.Run = lastScore.Run + 1
			scoreStruct.TotalScore += lastScore.TotalScore
		} else {
			scores = append(scores, *lastScore)
		}
	}
	scores = append(scores, scoreStruct)

	p.SaveScores(scores)
}

func tick(p Platform, s *State) error {
	for i := len(s.monsters) - 1; i >= 0; i-- {
		if s.monsters[i].monster().dead {
			// Remove the dead monster
			copy(s.monsters[i:], s.monsters[i+1:])
			s.monsters = s.monsters[:len(s.monsters)-1]
		} else {
			err := s.monsters[i].update(p, s)
			if err != nil {
				return err
			}
		}
	}

	if s.player.monster().dead {
		addScore(p, s.score, Lost)
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
