package main

import (
	"time"

	"github.com/veandco/go-sdl2/sdl"
)

const (
	PerFrameDuration = time.Second / 60
	size             = 20
	//Aqua             = 0xff00ffff
	Indigo           = 0xff4b0082
	//Violet           = 0xffee82ee
	//White            = 0xffffffff
)

func main() {
	dieIfErr(sdl.Init(sdl.INIT_AUDIO | sdl.INIT_VIDEO))
	defer sdl.Quit()

	window, err := sdl.CreateWindow(
		"AWESOME BROUGHLIKE",
		sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED,
		800, 600,
		sdl.WINDOW_FULLSCREEN_DESKTOP|sdl.WINDOW_INPUT_GRABBED)
	dieIfErr(err)

	defer func() { dieIfErr(window.Destroy()) }()

	surface, err := window.GetSurface()
	dieIfErr(err)

	var x int32 = 0
	var y int32 = 0

	draw := func() {
		dieIfErr(surface.FillRect(nil, Indigo))
		dieIfErr(surface.FillRect(&sdl.Rect{X: x * size, Y: y * size, W: size, H: size}, 0xff000000))
		dieIfErr(window.UpdateSurface())
	}

	for {
		start := time.Now()
		// We only want to allow at most a single input per frame.
		if event := sdl.PollEvent(); event != nil {
			switch e := event.(type) {
			case *sdl.QuitEvent:
				return
			case *sdl.KeyboardEvent:
				switch e.Keysym.Sym {
				case sdl.K_w:
					fallthrough
				case sdl.K_UP:
					y--
				case sdl.K_a:
					fallthrough
				case sdl.K_LEFT:
					x--
				case sdl.K_s:
					fallthrough
				case sdl.K_DOWN:
					y++
				case sdl.K_d:
					fallthrough
				case sdl.K_RIGHT:
					x++
				}
			}
		}

		draw()

		time.Sleep(time.Until(start.Add(PerFrameDuration)))
	}
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
