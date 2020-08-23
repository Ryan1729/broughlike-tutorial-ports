package main

import (
	"github.com/veandco/go-sdl2/sdl"
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
	dieIfErr(surface.FillRect(nil, 0xffffffff))

	const size = 20
	rect := sdl.Rect{X: 0, Y: 0, W: size, H: size}
	dieIfErr(surface.FillRect(&rect, 0xff000000))
	dieIfErr(window.UpdateSurface())

	for {
		for event := sdl.PollEvent(); event != nil; event = sdl.PollEvent() {
			if _, isQuit := event.(*sdl.QuitEvent); isQuit {
				return
			}
		}
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
