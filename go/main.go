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
	// Violet           = 0xffee82ee
	// White            = 0xffffffff.
)

type State struct {
	x, y     int32
	tileSize int32
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
		tileSize: calcTileSize(w, h),
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
	dieIfErr(renderer.SetDrawColor(0, 0, 0, 0xff))
	dieIfErr(renderer.FillRect(
		&sdl.Rect{X: s.x * s.tileSize, Y: s.y * s.tileSize, W: s.tileSize, H: s.tileSize}))
	renderer.Present()
}

func calcTileSize(w, h int32) int32 {
	return min(
		w/(NumTiles+UIWidth),
		h/NumTiles,
	)
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
