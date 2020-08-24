package main

import (
	"time"

	"github.com/veandco/go-sdl2/sdl"
)

const (
	PerFrameDuration = time.Second / 60

	NumTiles = 9
	UIWidth  = 4

	// Aqua             = 0xff00ffff.
	// Violet           = 0xffee82ee.
)

type State struct {
	x, y  int32
	sizes Sizes
}

func main() {
	dieIfErr(sdl.Init(sdl.INIT_AUDIO | sdl.INIT_VIDEO))
	defer sdl.Quit()

	window, err := sdl.CreateWindow(
		"AWESOME BROUGHLIKE",
		sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED,
		800, 600,
		sdl.WINDOW_FULLSCREEN_DESKTOP|sdl.WINDOW_ALLOW_HIGHDPI|sdl.WINDOW_INPUT_GRABBED)
	dieIfErr(err)
	defer func() { dieIfErr(window.Destroy()) }()

	renderer, err := sdl.CreateRenderer(window, -1, sdl.RENDERER_ACCELERATED)
	dieIfErr(err)

	w, h, err := renderer.GetOutputSize()
	dieIfErr(err)

	var s State = State{
		sizes: NewSizes(w, h),
	}

	for {
		start := time.Now()
		// We only want to allow at most a single input per frame.
		if event := sdl.PollEvent(); event != nil {
			switch e := event.(type) {
			case *sdl.QuitEvent:
				return
			case *sdl.KeyboardEvent:
				if e.State == sdl.PRESSED {
					switch e.Keysym.Sym {
					case sdl.K_w:
						fallthrough
					case sdl.K_UP:
						s.y--
					case sdl.K_a:
						fallthrough
					case sdl.K_LEFT:
						s.x--
					case sdl.K_s:
						fallthrough
					case sdl.K_DOWN:
						s.y++
					case sdl.K_d:
						fallthrough
					case sdl.K_RIGHT:
						s.x++
					}
				}
			}
		}

		draw(renderer, &s)

		time.Sleep(time.Until(start.Add(PerFrameDuration)))
	}
}

func draw(renderer *sdl.Renderer, s *State) {
	dieIfErr(renderer.SetDrawColor(0x4b, 0, 0x82, 0xff))
	dieIfErr(renderer.Clear())

	sizes := s.sizes

	dieIfErr(renderer.SetDrawColor(0xff, 0xff, 0xff, 0xff))
	// the -1 and +2 business makes the border lie just outside the actual
	// play area
	dieIfErr(renderer.DrawRect(
		&sdl.Rect{
			X: sizes.playAreaX - 1,
			Y: sizes.playAreaY - 1,
			W: sizes.playAreaW + 2,
			H: sizes.playAreaH + 2,
		}))

	dieIfErr(renderer.SetDrawColor(0, 0, 0, 0xff))
	dieIfErr(renderer.FillRect(
		&sdl.Rect{
			X: sizes.playAreaX + s.x*sizes.tile,
			Y: sizes.playAreaY + s.y*sizes.tile,
			W: sizes.tile,
			H: sizes.tile,
		}))
	renderer.Present()
}

type Sizes struct {
	playAreaX,
	playAreaY,
	playAreaW,
	playAreaH, tile int32
}

func NewSizes(w, h int32) Sizes {
	tile := min(
		w/(NumTiles+UIWidth),
		h/NumTiles,
	)
	playAreaW, playAreaH := tile*(NumTiles+UIWidth), tile*NumTiles
	playAreaX, playAreaY := (w-playAreaW)/2, (h-playAreaH)/2

	return Sizes{
		playAreaX,
		playAreaY,
		playAreaW,
		playAreaH,
		tile,
	}
}

func min(a, b int32) int32 {
	if a < b {
		return a
	}

	return b
}

func dieIfErr(err error) {
	if err != nil {
		die(err)
	}
}

func die(err error) {
	msgErr := sdl.ShowSimpleMessageBox(sdl.MESSAGEBOX_ERROR, "Error", err.Error(), nil)
	if msgErr == nil {
		panic(err)
	} else {
		panic(msgErr.Error() + "\n" + err.Error())
	}
}
