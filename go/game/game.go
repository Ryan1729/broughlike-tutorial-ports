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
	One   KeyType = iota
	Two   KeyType = iota
	Three KeyType = iota
	Four  KeyType = iota
	Five  KeyType = iota
	Six   KeyType = iota
	Seven KeyType = iota
	Eight KeyType = iota
	Nine  KeyType = iota
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
	// type Direction is an x, y pair of Delta values, in that order.
	Direction = [2]Delta
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
	// Should only be within the range [0, 1].
	Alpha     float32
	KeyType   uint8
	gameState uint8
	Points    uint64
	Run       uint64
	WonOrLost bool
	Colour    uint32
	numSpells uint8
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
	x      SubTilePosition
	y      SubTilePosition
}

type State struct {
	player       Player
	tiles        Tiles
	monsters     []Monstrous
	spells       SpellMap
	shake        shake
	spawnRate    counter
	spawnCounter counter
	level        Level
	state        gameState
	score        Points
	numSpells    numSpells
}

func (s *State) Input(p Platform, keyType KeyType) error {
	var err error = nil
	switch s.state {
	case title:
		err = startGame(s)
	case dead:
		s.state = title
	case running:
		switch {
		case keyType == Up:
			err = s.player.tryMove(p, s, 0, -1)
		case keyType == Left:
			err = s.player.tryMove(p, s, -1, 0)
		case keyType == Down:
			err = s.player.tryMove(p, s, 0, 1)
		case keyType == Right:
			err = s.player.tryMove(p, s, 1, 0)
		case keyType >= One && keyType <= Nine:
			// One maps to 0, Two maps to 1 and so forth.
			err = s.player.castSpell(p, s, int(keyType-One))
		case keyType == Other:
			fallthrough
		default:
		}
	}

	return err
}

func startGame(s *State) error {
	s.level = 1
	s.score = 0
	s.numSpells = 1

	if s.spells == nil {
		s.spells = getSpellMap()
	}

	err := startLevel(s, startingHp, nil)
	if err != nil {
		return err
	}

	s.state = running

	return nil
}

func startLevel(s *State, playerHp HP, playerSpells []SpellName) error {
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

	s.player = *NewPlayerStruct(s, startingTileish)

	s.player.monster().hp = playerHp

	if len(playerSpells) > 0 {
		s.player.spells = playerSpells
	}

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
	SpellList TextSize = iota
)

type TextJustification uint8

// Any Platform interface implementations only needs to handle these values for
// TextJustification.
const (
	Plain    TextJustification = iota
	Centered TextJustification = iota
)

type Sound uint8

// Any Platform interface implementations only needs to handle these values for
// Sound.
const (
	Hit1       Sound = iota
	Hit2       Sound = iota
	Treasure   Sound = iota
	NewLevel   Sound = iota
	SpellSound Sound = iota
)

type Platform interface {
	SubTileSprite(
		sprite SpriteIndex,
		x, y, shakeX, shakeY SubTilePosition,
		alpha Alpha,
	)
	Overlay()
	Text(text string,
		size TextSize,
		justification TextJustification,
		textY SubTilePosition,
		color Colour,
	)
	GetScores() []Score
	SaveScores(scores []Score)
	Sound(sound Sound)
}

func sprite(p Platform, sprite SpriteIndex, x, y Position, shake shake) {
	subTileSprite(
		p,
		sprite,
		SubTilePosition(x),
		SubTilePosition(y),
		shake,
	)
}

func spriteWithAlpha(p Platform, sprite SpriteIndex, x, y Position, shake shake, alpha Alpha) {
	p.SubTileSprite(
		sprite,
		SubTilePosition(x),
		SubTilePosition(y),
		shake.x,
		shake.y,
		alpha,
	)
}

func subTileSprite(p Platform, sprite SpriteIndex, x, y SubTilePosition, shake shake) {
	p.SubTileSprite(
		sprite,
		x,
		y,
		shake.x,
		shake.y,
		1.0,
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

	for i := 0; i < len(s.player.spells); i++ {
		spellText := strconv.FormatUint(uint64(i+1), 10) + ") " + s.player.spells[i].String()
		p.Text(spellText, SpellList, Plain, SubTilePosition(SubTileUnit)*5/4+SubTilePosition(i)*SubTileUnit/2, aqua)
	}
}

func screenshake(shake *shake) {
	shake.amount.dec()

	shakeAmount := SubTilePosition(shake.amount.value) * SubTileUnit
	shakeAngle := randomFloat() * math.Pi * 2
	shake.x = SubTilePosition(
		math.Round(math.Cos(shakeAngle)*float64(shakeAmount)) * OneOverSubTileUnit,
	)
	shake.y = SubTilePosition(
		math.Round(math.Sin(shakeAngle)*float64(shakeAmount)) * OneOverSubTileUnit,
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

	err := s.player.update(p, s)
	if err != nil {
		return err
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
