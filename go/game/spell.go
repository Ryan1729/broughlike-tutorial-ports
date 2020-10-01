package game

type SpellName uint8

const (
	NoSpell   SpellName = iota
	WOOP      SpellName = iota
	QUAKE     SpellName = iota
	MAELSTROM SpellName = iota
	MULLIGAN  SpellName = iota
	AURA      SpellName = iota
	DASH      SpellName = iota
	DIG       SpellName = iota
	KINGMAKER SpellName = iota
	ALCHEMY   SpellName = iota
	POWER     SpellName = iota
)

func (s SpellName) String() string {
	switch s {
	case NoSpell:
		// This is blank so that we get blanks in the displayed spell list.
		return ""
	case WOOP:
		return "WOOP"
	case QUAKE:
		return "QUAKE"
	case MAELSTROM:
		return "MAELSTROM"
	case MULLIGAN:
		return "MULLIGAN"
	case AURA:
		return "AURA"
	case DASH:
		return "DASH"
	case DIG:
		return "DIG"
	case KINGMAKER:
		return "KINGMAKER"
	case ALCHEMY:
		return "ALCHEMY"
	case POWER:
		return "POWER"
	default:
		return "Unknown Spell"
	}
}

type Spell func(p Platform, s *State) error

type SpellMap map[SpellName]Spell

func woop(p Platform, s *State) error {
	tileish, err := s.tiles.randomPassable()
	if err != nil {
		return err
	}

	return move(p, s, s.player, tileish)
}

func quake(p Platform, s *State) error {
	var i, j Position
	for j = 0; j < NumTiles; j++ {
		for i = 0; i < NumTiles; i++ {
			tile := s.tiles.get(i, j).tile()
			if tile.monster != nil {
				numWalls := 4 - len(s.tiles.getAdjacentPassableNeighbors(tile))
				hit(p, tile.monster, HP(numWalls*2))
			}
		}
	}
	s.shake.amount = counter{20}

	return nil
}

func maelstrom(p Platform, s *State) error {
	for i := 0; i < len(s.monsters); i++ {
		tileish, err := s.tiles.randomPassable()
		if err != nil {
			return err
		}

		err = move(p, s, s.monsters[i], tileish)
		if err != nil {
			return err
		}

		s.monsters[i].monster().teleportCounter = counter{2}
	}

	return nil
}

func mulligan(p Platform, s *State) error {
	return startLevel(s, 1, s.player.spells)
}

func aura(p Platform, s *State) error {
	for _, tileish := range s.tiles.getAdjacentNeighbors(s.player.tileish) {
		tileish.setEffect(13)
		t := tileish.tile()
		if t.monster != nil {
			t.monster.monster().heal(1)
		}
	}
	s.player.tileish.setEffect(13)
	s.player.monster().heal(1)

	return nil
}

func dash(p Platform, s *State) error {
	newTile := s.player.tileish
	for {
		testTileish := s.tiles.getNeighbor(newTile, s.player.lastMove[0], s.player.lastMove[1])
		testTile := testTileish.tile()
		if testTile.passable && testTile.monster == nil {
			newTile = testTile
		} else {
			break
		}
	}
	if s.player.tileish != newTile {
		err := move(p, s, s.player, newTile)
		if err != nil {
			return err
		}

		for _, t := range s.tiles.getAdjacentNeighbors(newTile) {
			monster := t.tile().monster
			if monster != nil {
				t.setEffect(14)
				monster.monster().stunned = true
				hit(p, monster, 1)
			}
		}
	}

	return nil
}

func dig(p Platform, s *State) error {
	var i, j Position
	for j = 0; j < NumTiles; j++ {
		for i = 0; i < NumTiles; i++ {
			tile := s.tiles.get(i, j)
			if !tile.tile().passable {
				s.tiles.replace(tile, NewFloor)
			}
		}
	}

	s.player.tileish.setEffect(13)
	s.player.heal(2)

	return nil
}

func kingmaker(p Platform, s *State) error {
	for _, m := range s.monsters {
		m.monster().heal(1)
		m.monster().tileish.tile().treasure = true
	}

	return nil
}

func alchemy(p Platform, s *State) error {
	for _, tileish := range s.tiles.getAdjacentNeighbors(s.player.tileish) {
		t := tileish.tile()
		if !t.passable && inBounds(t.x, t.y) {
			s.tiles.replace(tileish, NewFloor)

			s.tiles.get(t.x, t.y).tile().treasure = true
		}
	}

	return nil
}

func power(p Platform, s *State) error {
	s.player.monster().bonusAttack = 5

	return nil
}

// We make this a function to avoid what would otherwise be a global variable,
// since golang doesn't support const maps.
func getSpellMap() SpellMap {
	return map[SpellName]Spell{
		// We intentionally leave NoSpell out of the map, so it doesn't end up in the
		// output of shuffledSpellNames.
		WOOP:      woop,
		QUAKE:     quake,
		MAELSTROM: maelstrom,
		MULLIGAN:  mulligan,
		AURA:      aura,
		DASH:      dash,
		DIG:       dig,
		KINGMAKER: kingmaker,
		ALCHEMY:   alchemy,
		POWER:     power,
	}
}

func shuffledSpellNames(spells SpellMap) []SpellName {
	i := 0
	names := make([]SpellName, len(spells))
	for k := range spells {
		names[i] = k
		i++
	}

	return shuffleSpellNamesInPlace(names)
}
