package main

import (
	"flag"
	"fmt"
	"math/rand"
	"os"
	"time"

	"github.com/Ryan1729/broughlike-tutorial-ports/go/assets"
	"github.com/Ryan1729/broughlike-tutorial-ports/go/game"
	"github.com/veandco/go-sdl2/img"
	"github.com/veandco/go-sdl2/sdl"
	"github.com/veandco/go-sdl2/ttf"
)

const (
	PerFrameDuration = time.Second / 60
)

func handleFlags() {
	var licenseFlag *bool = flag.Bool("license", false, "Print license info then exit.")

	defaultUsage := flag.Usage
	flag.Usage = func() {
		defaultUsage()
		fmt.Println("  \"\"")
		fmt.Println("    \tRun without args to play the game.")
	}

	flag.Parse()

	if *licenseFlag {
		fmt.Println("program By Ryan Wiedemann.")
		fmt.Println("Source code and license info available at https://github.com/Ryan1729/broughlike-tutorial-ports/")
		fmt.Println("")
		fmt.Println("License for the font:")
		fmt.Println(string(assets.FontLicense))

		os.Exit(0)
	}
}

func main() {
	handleFlags()

	dieIfErr(ttf.Init())
	defer ttf.Quit()

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

		doFrame(&platform, &s)

		time.Sleep(time.Until(start.Add(PerFrameDuration)))
	}
}

func doFrame(platform *SDL2Platform, s *game.State) {
	platform.Clear()
	game.Draw(platform, s)
	platform.renderer.Present()
}

// SDL2Platform implements the game.Platform interface.
type SDL2Platform struct {
	renderer *sdl.Renderer
	assets   Assets
	sizes    Sizes
}

func NewSDL2Platform(window *sdl.Window) SDL2Platform {
	renderer, err := sdl.CreateRenderer(window, -1, sdl.RENDERER_ACCELERATED)
	dieIfErr(err)
	dieIfErr(renderer.SetDrawBlendMode(sdl.BLENDMODE_BLEND))

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
	renderer := p.renderer
	sizes := &p.sizes

	var font *ttf.Font
	if size == game.Title {
		font = p.assets.titleFont
	} else {
		font = p.assets.uiFont
	}

	width, height, err := font.SizeUTF8(text)
	dieIfErr(err)
	w, h := int32(width), int32(height)

	var textX int32
	if justification == game.Centered {
		textX = (sizes.playAreaW - w) / 2
	} else {
		textX = sizes.playAreaW - game.UIWidth*sizes.tile + 25
	}

	textSurface, err := font.RenderUTF8Blended(
		text,
		sdl.Color{
			R: byte(color & 0xff),
			G: byte((color >> 8) & 0xff),
			B: byte((color >> 16) & 0xff),
			A: byte(color >> 24),
		},
	)
	dieIfErr(err)
	defer textSurface.Free()

	// Question: would it be worth it to cache these?
	textTexture, err := renderer.CreateTextureFromSurface(textSurface)
	dieIfErr(err)
	defer func() {
		dieIfErr(textTexture.Destroy())
	}()

	dieIfErr(p.renderer.Copy(
		p.assets.spritesheet,
		nil,
		&sdl.Rect{X: textX, Y: int32(textY), W: w, H: h}))
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
	uiFont      *ttf.Font
	titleFont   *ttf.Font
	// Eventually we can add the sounds to this struct as well.
}

func loadAssets(renderer *sdl.Renderer) Assets {
	spritesheetRW, err := sdl.RWFromMem(assets.Spritesheet)
	dieIfErr(err)

	spritesheet, err := img.LoadTextureRW(renderer, spritesheetRW, false)
	dieIfErr(err)

	// We get an error from SDL2 if we try to use the same RWOps for both fonts
	uiFontRW, err := sdl.RWFromMem(assets.Font)
	dieIfErr(err)

	uiFont, err := ttf.OpenFontRW(uiFontRW, 0, int(game.UI)+10)
	dieIfErr(err)

	titleFontRW, err := sdl.RWFromMem(assets.Font)
	dieIfErr(err)

	titleFont, err := ttf.OpenFontRW(titleFontRW, 0, int(game.Title)+10)
	dieIfErr(err)

	return Assets{
		spritesheet,
		uiFont,
		titleFont,
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
