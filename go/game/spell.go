package game

type SpellName uint8

const (
	NoSpell SpellName = iota
	WOOP    SpellName = iota
)

func (s SpellName) String() string {
	switch s {
	case NoSpell:
		// This is blank so that we get blanks in the displayed spell list.
		return ""
	case WOOP:
		return "WOOP"
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
