package main

import (
	"fmt"
	"flag"
	"math/rand"
	"time"

	"github.com/Ryan1729/broughlike-tutorial-ports/go/assets"
	"github.com/Ryan1729/broughlike-tutorial-ports/go/game"
	"github.com/veandco/go-sdl2/img"
	"github.com/veandco/go-sdl2/sdl"
)       

const (
	PerFrameDuration = time.Second / 60
)

var licenseFlag *bool = flag.Bool("license", false, "Print license info then exit.")

func init() {
	defaultUsage := flag.Usage
	flag.Usage = func() {
	    defaultUsage()
	    fmt.Println("  \"\"")
	    fmt.Println("    \tRun without args to play the game.")
	}
}

func main() {
	flag.Parse()
	if *licenseFlag {
		fmt.Println("program By Ryan Wiedemann. Source code and license info available at https://github.com/Ryan1729/broughlike-tutorial-ports/")
		fmt.Println("")
		fmt.Println("License for the font:")
		fmt.Println(string(assets.FontLicense))

		return
	}
	
	dieIfErr(sdl.Init(sdl.INIT_AUDIO | sdl.INIT_VIDEO))
	defer sdl.Quit()

	window, err := sdl.CreateWindow(
		"AWESOME BROUGHLIKE",
		sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED,
		800, 600,
		sdl.WINDOW_FULLSCREEN_DESKTOP|sdl.WINDOW_ALLOW_HIGHDPI|sdl.WINDOW_INPUT_GRABBED)
	dieIfErr(err)
	defer func() { dieIfErr(window.Destroy()) }()

	platform, s := NewSDL2Platform(window), game.State{}

	seedRNG()

	for {
		start := time.Now()
		// We only want to allow at most a single input per frame.
		if event := sdl.PollEvent(); event != nil {
			switch e := event.(type) {
			case *sdl.QuitEvent:
				return
			case *sdl.KeyboardEvent:
				if e.State == sdl.PRESSED {
					var keyType game.KeyType
					switch e.Keysym.Sym {
					case sdl.K_w:
						fallthrough
					case sdl.K_UP:
						keyType = game.Up
					case sdl.K_a:
						fallthrough
					case sdl.K_LEFT:
						keyType = game.Left
					case sdl.K_s:
						fallthrough
					case sdl.K_DOWN:
						keyType = game.Down
					case sdl.K_d:
						fallthrough
					case sdl.K_RIGHT:
						keyType = game.Right
					}

					dieIfErr(s.Input(keyType))
				}
			}
		}

		platform.Clear()
		game.Draw(&platform, &s)
		platform.renderer.Present()

		time.Sleep(time.Until(start.Add(PerFrameDuration)))
	}
}

// SDL2Platform implements the game.Platform interface.
type SDL2Platform struct {
	renderer *sdl.Renderer
	assets   Assets
	sizes    Sizes
}

func NewSDL2Platform(window *sdl.Window) SDL2Platform {
	renderer, err := sdl.CreateRenderer(window, -1, sdl.RENDERER_ACCELERATED)
	dieIfErr(renderer.SetDrawBlendMode(sdl.BLENDMODE_BLEND))
	dieIfErr(err)

	w, h, err := renderer.GetOutputSize()
	dieIfErr(err)

	return SDL2Platform{
		renderer: renderer,
		assets:   loadAssets(renderer),
		sizes:    NewSizes(w, h),
	}
}

func (p *SDL2Platform) Clear() {
	renderer := p.renderer
	sizes := &p.sizes

	dieIfErr(renderer.SetDrawColor(0x4b, 0, 0x82, 0xff))
	dieIfErr(renderer.Clear())

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
}

func (p *SDL2Platform) SubTileSprite(sprite game.SpriteIndex, x, y game.SubTilePosition) {
	sizes := &p.sizes

	dieIfErr(p.renderer.Copy(
		p.assets.spritesheet,
		&sdl.Rect{
			X: int32(sprite) * 16,
			Y: 0,
			W: 16,
			H: 16,
		},
		&sdl.Rect{
			X: sizes.playAreaX + int32(x*game.SubTilePosition(sizes.tile)),
			Y: sizes.playAreaY + int32(y*game.SubTilePosition(sizes.tile)),
			W: sizes.tile,
			H: sizes.tile,
		}))
}

func (p *SDL2Platform) Overlay() {
	renderer := p.renderer
	sizes := &p.sizes

	dieIfErr(renderer.SetDrawColor(0, 0, 0, 0xbf))
	dieIfErr(renderer.FillRect(
		&sdl.Rect{
			X: sizes.playAreaX,
			Y: sizes.playAreaY,
			W: sizes.playAreaW,
			H: sizes.playAreaH,
		}))
}

func (p *SDL2Platform) Text(
	text string,
	size game.TextSize,
	justification game.TextJustification,
	textY game.SubTilePosition,
	color uint32,
) {
	// Reminder: complete
}

func seedRNG() {
	seed := time.Now().UnixNano()
	println(seed)
	rand.Seed(seed)
}

type Sizes struct {
	playAreaX,
	playAreaY,
	playAreaW,
	playAreaH, tile int32
}

func NewSizes(w, h int32) Sizes {
	tile := min(
		w/(game.NumTiles+game.UIWidth),
		h/game.NumTiles,
	)
	playAreaW, playAreaH := tile*(game.NumTiles+game.UIWidth), tile*game.NumTiles
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

type Assets struct {
	spritesheet *sdl.Texture
	// Eventually we can add the sounds to this struct as well.
}

func loadAssets(renderer *sdl.Renderer) Assets {
	spritesheetRW, err := sdl.RWFromMem(assets.Spritesheet)
	dieIfErr(err)

	spritesheet, err := img.LoadTextureRW(renderer, spritesheetRW, false)
	dieIfErr(err)

	return Assets{
		spritesheet,
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
