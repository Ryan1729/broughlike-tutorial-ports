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

func randomRange(min, max Position) Position {
	return rand.Int31n(max-min+1) + min
}
