package game

import (
	"math/rand"
)

type tryToError struct {
	description string
}

func (e tryToError) Error() string {
	return e.description
}

func tryTo(description string, callback func() bool) error {
	for timeout := 1000; timeout > 0; timeout-- {
		if callback() {
			return nil
		}
	}

	return tryToError{description: "Timeout while trying to " + description}
}

func randomRangePosition(min, max Position) Position {
	return Position(rand.Int31n(int32(max-min+1))) + min
}

func randomRangeInt(min, max int) int {
	return rand.Intn(max-min+1) + min
}

func randomFloat() float64 {
	return rand.Float64()
}

type counter struct {
	value uint8
}

func (c *counter) dec() {
	if c.isActive() {
		c.value--
	}
}

func (c *counter) isActive() bool {
	return c.value > 0
}

func rightPad(textArray ...string) string {
	finalText := ""

	for _, text := range textArray {
		for i := len(text); i < 10; i++ {
			text += " "
		}
		finalText += text
	}

	return finalText
}

// Mutates the passed in slice, but also returns it to be convenient.
func shuffleTileishInPlace(slice []Tileish) []Tileish {
	length := len(slice)
	for i := 1; i < length; i++ {
		r := randomRangeInt(0, i)
		slice[i], slice[r] = slice[r], slice[i]
	}

	return slice
}

// Mutates the passed in slice, but also returns it to be convenient.
func shuffleMonsterMakersInPlace(slice []MonsterMaker) []MonsterMaker {
	length := len(slice)
	for i := 1; i < length; i++ {
		r := randomRangeInt(0, i)
		slice[i], slice[r] = slice[r], slice[i]
	}

	return slice
}

// Mutates the passed in slice, but also returns it to be convenient.
func shuffleSpellNamesInPlace(slice []SpellName) []SpellName {
	length := len(slice)
	for i := 1; i < length; i++ {
		r := randomRangeInt(0, i)
		slice[i], slice[r] = slice[r], slice[i]
	}

	return slice
}
