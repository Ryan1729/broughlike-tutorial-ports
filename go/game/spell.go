package game

type SpellName uint8

const (
	NoSpell   SpellName = iota
	WOOP      SpellName = iota
	QUAKE     SpellName = iota
	MAELSTROM SpellName = iota
	MULLIGAN  SpellName = iota
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
	default:
		return "Unknown Spell"
	}
}

type Spell func(p Platform, s *State) error

type SpellMap map[SpellName]Spell

// We make this a function to avoid what would otherwise be a global variable,
// since golang doesn't support const maps.
func getSpellMap() SpellMap {
	return map[SpellName]Spell{
		// We intentionally leave NoSpell out of the map, so it doesn't end up in the
		// output of shuffledSpellNames.
		WOOP: func(p Platform, s *State) error {
			tileish, err := s.tiles.randomPassable()
			if err != nil {
				return err
			}

			return move(p, s, s.player, tileish)
		},
		QUAKE: func(p Platform, s *State) error {
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
		},
		MAELSTROM: func(p Platform, s *State) error {
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
		},
		MULLIGAN: func(p Platform, s *State) error {
			return startLevel(s, 1, s.player.spells)
		},
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
