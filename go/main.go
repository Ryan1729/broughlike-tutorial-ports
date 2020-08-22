package main

import (
	"github.com/veandco/go-sdl2/sdl"
)

func main() {
	if err := sdl.Init(sdl.INIT_AUDIO | sdl.INIT_VIDEO); err != nil {
		die(err)
	}
	defer sdl.Quit()

	window, err := sdl.CreateWindow(
		"AWESOME BROUGHLIKE",
		sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED,
		800, 600,
		sdl.WINDOW_FULLSCREEN_DESKTOP|sdl.WINDOW_INPUT_GRABBED)
	if err != nil {
		die(err)
	}
	defer window.Destroy()

	surface, err := window.GetSurface()
	if err != nil {
		die(err)
	}
	surface.FillRect(nil, 0xffffffff)

	rect := sdl.Rect{0, 0, 20, 20}
	surface.FillRect(&rect, 0xff000000)
	window.UpdateSurface()

	for {
		for event := sdl.PollEvent(); event != nil; event = sdl.PollEvent() {
			switch event.(type) {
			case *sdl.QuitEvent:
				return
			}
		}
	}
}

func die(err error) {
	sdl.ShowSimpleMessageBox(sdl.MESSAGEBOX_ERROR, "Error", err.Error(), nil)
	panic(err)
}
