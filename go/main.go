package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"math/rand"
	"os"
	"path/filepath"
	"time"

	"github.com/Ryan1729/broughlike-tutorial-ports/go/assets"
	"github.com/Ryan1729/broughlike-tutorial-ports/go/game"
	"github.com/veandco/go-sdl2/img"
	"github.com/veandco/go-sdl2/mix"
	"github.com/veandco/go-sdl2/sdl"
	"github.com/veandco/go-sdl2/ttf"
)

const (
	PerFrameDuration = time.Second / 60
)

type config struct {
	saveFile *os.File
}

func handleFlags() config {
	var licenseFlag *bool = flag.Bool("license", false, "Print license info then exit.")
	var saveDirFlag *string = flag.String("save-dir", "", "Override save directory")

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

	saveFile, err := openSaveFile(*saveDirFlag)
	// We assume that most people would rather just play the game without
	// high-scores, if tere's some problem loading them. But if someone does
	// care, we should give them the information to fix it.
	if err != nil {
		fmt.Println(err)
	}

	return config{
		saveFile,
	}
}

type couldNotWriteToExeDirError struct {
	exeDirPath string
}

func (e *couldNotWriteToExeDirError) Error() string {
	return "Could not write to exe dir:" + e.exeDirPath
}

func openSaveFile(saveDir string) (*os.File, error) {
	if !isWritableDir(saveDir) {
		exePath, err := os.Executable()
		if err != nil {
			return nil, err
		}
		exeDirPath := filepath.Dir(exePath)

		if isWritableDir(exeDirPath) {
			saveDir = exeDirPath
		} else {
			return nil, &couldNotWriteToExeDirError{exeDirPath}
		}
	}

	saveFileName := filepath.Join(saveDir, game.TitleString+".sav")

	return os.OpenFile(saveFileName, os.O_RDWR|os.O_CREATE, 0666)
}

func isWritableDir(dirPath string) bool {
	info, err := os.Stat(dirPath)
	if err != nil {
		return false
	}

	const writableDir os.FileMode = os.ModeDir | 0200

	return (info.Mode() & writableDir) == writableDir
}

func closeConfig(config *config) {
	if config.saveFile != nil {
		if err := config.saveFile.Sync(); err != nil {
			fmt.Println(err)
		}

		if err := config.saveFile.Close(); err != nil {
			fmt.Println(err)
		}
	}
}

func destroyWindow(window *sdl.Window) {
	dieIfErr(window.Destroy())
}

func sdlInit() {
	dieIfErr(ttf.Init())
	dieIfErr(sdl.Init(sdl.INIT_AUDIO | sdl.INIT_VIDEO))

	// The channels here the output channels, not the mixing channels.
	// See https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_11.html
	dieIfErr(mix.OpenAudio(mix.DEFAULT_FREQUENCY, mix.DEFAULT_FORMAT, mix.DEFAULT_CHANNELS, mix.DEFAULT_CHUNKSIZE))

	mix.AllocateChannels(16)
}

func sdlQuit() {
	sdl.Quit()
	ttf.Quit()
	mix.CloseAudio()
}

func main() {
	config := handleFlags()
	defer closeConfig(&config)

	sdlInit()
	defer sdlQuit()

	window, err := sdl.CreateWindow(
		"AWESOME BROUGHLIKE",
		sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED,
		800, 600,
		sdl.WINDOW_FULLSCREEN_DESKTOP|sdl.WINDOW_ALLOW_HIGHDPI|sdl.WINDOW_INPUT_GRABBED)
	dieIfErr(err)
	defer destroyWindow(window)

	platform, s := NewSDL2Platform(window, config), game.State{}

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
					dieIfErr(s.Input(&platform, keyCodetoKeyType(e.Keysym.Sym)))
				}
			}
		}

		doFrame(&platform, &s)

		time.Sleep(time.Until(start.Add(PerFrameDuration)))
	}
}

//nolint:funlen, gocyclo // This function does exactly one cohesive thing,
// splitting it up further would be counter-productive.
func keyCodetoKeyType(keycode sdl.Keycode) game.KeyType {
	var keyType game.KeyType
	switch keycode {
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
	case sdl.K_1:
		fallthrough
	case sdl.K_F1:
		fallthrough
	case sdl.K_KP_1:
		keyType = game.One
	case sdl.K_2:
		fallthrough
	case sdl.K_F2:
		fallthrough
	case sdl.K_KP_2:
		keyType = game.Two
	case sdl.K_3:
		fallthrough
	case sdl.K_F3:
		fallthrough
	case sdl.K_KP_3:
		keyType = game.Three
	case sdl.K_4:
		fallthrough
	case sdl.K_F4:
		fallthrough
	case sdl.K_KP_4:
		keyType = game.Four
	case sdl.K_5:
		fallthrough
	case sdl.K_F5:
		fallthrough
	case sdl.K_KP_5:
		keyType = game.Five
	case sdl.K_6:
		fallthrough
	case sdl.K_F6:
		fallthrough
	case sdl.K_KP_6:
		keyType = game.Six
	case sdl.K_7:
		fallthrough
	case sdl.K_F7:
		fallthrough
	case sdl.K_KP_7:
		keyType = game.Seven
	case sdl.K_8:
		fallthrough
	case sdl.K_F8:
		fallthrough
	case sdl.K_KP_8:
		keyType = game.Eight
	case sdl.K_9:
		fallthrough
	case sdl.K_F9:
		fallthrough
	case sdl.K_KP_9:
		keyType = game.Nine
	}

	return keyType
}

func doFrame(platform *SDL2Platform, s *game.State) {
	platform.Clear()
	game.Draw(platform, s)
	platform.renderer.Present()
}

// SDL2Platform implements the game.Platform interface.
type SDL2Platform struct {
	config             config
	renderer           *sdl.Renderer
	assets             Assets
	sizes              Sizes
	isScoresCacheValid bool
	scoresCache        []game.Score
}

func NewSDL2Platform(window *sdl.Window, config config) SDL2Platform {
	renderer, err := sdl.CreateRenderer(window, -1, sdl.RENDERER_ACCELERATED)
	dieIfErr(err)
	dieIfErr(renderer.SetDrawBlendMode(sdl.BLENDMODE_BLEND))

	w, h, err := renderer.GetOutputSize()
	dieIfErr(err)

	return SDL2Platform{
		config:   config,
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

func (p *SDL2Platform) SubTileSprite(
	sprite game.SpriteIndex,
	x, y, shakeX, shakeY game.SubTilePosition,
	alpha game.Alpha,
) {
	sizes := &p.sizes

	dieIfErr(p.assets.spritesheet.SetAlphaMod(uint8(alpha * 255.0)))

	dieIfErr(p.renderer.Copy(
		p.assets.spritesheet,
		&sdl.Rect{
			X: int32(sprite) * 16,
			Y: 0,
			W: 16,
			H: 16,
		},
		&sdl.Rect{
			X: sizes.playAreaX + int32(x*game.SubTilePosition(sizes.tile)+shakeX),
			Y: sizes.playAreaY + int32(y*game.SubTilePosition(sizes.tile)+shakeY),
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
	colour game.Colour,
) {
	renderer := p.renderer
	sizes := &p.sizes

	var font *ttf.Font
	switch size {
	case game.Title:
		font = p.assets.fonts.title
	case game.ScoreList:
		font = p.assets.fonts.scoreList
	case game.SpellList:
		font = p.assets.fonts.spellList
	case game.UI:
		fallthrough
	default:
		font = p.assets.fonts.ui
	}

	width, height, err := font.SizeUTF8(text)
	dieIfErr(err)
	w, h := int32(width), int32(height)

	var textX int32
	if justification == game.Centered {
		textX = sizes.playAreaX + ((sizes.playAreaW - w) / 2)
	} else {
		textX = sizes.playAreaX + (sizes.playAreaW - game.UIWidth*sizes.tile + 25)
	}

	textSurface, err := font.RenderUTF8Blended(
		text,
		sdl.Color{
			R: byte(colour & 0xff),
			G: byte((colour >> 8) & 0xff),
			B: byte((colour >> 16) & 0xff),
			A: byte(colour >> 24),
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
		textTexture,
		nil,
		&sdl.Rect{
			X: textX,
			Y: int32(textY * game.SubTilePosition(sizes.tile) * game.OneOverSubTileUnit),
			W: w,
			H: h,
		}))
}

func (p *SDL2Platform) Sound(sound game.Sound) {
	switch sound {
	case game.Hit1:
		_, err := p.assets.hit1.Play(-1, 0)
		dieIfErr(err)
	case game.Hit2:
		_, err := p.assets.hit2.Play(-1, 0)
		dieIfErr(err)
	case game.Treasure:
		_, err := p.assets.treasure.Play(-1, 0)
		dieIfErr(err)
	case game.NewLevel:
		_, err := p.assets.newLevel.Play(-1, 0)
		dieIfErr(err)
	case game.SpellSound:
		_, err := p.assets.spell.Play(-1, 0)
		dieIfErr(err)
	default:
		fmt.Println("Unknown sound")
	}
}

// The game should not have to know or care about how we decide to serialize
// data on disk.

type scoreJSON struct {
	Score      game.Points
	Run        game.Run
	TotalScore game.Points
	Active     game.WonOrLost
}

func toGameScores(scoreJSONs []scoreJSON) []game.Score {
	scores := make([]game.Score, 0, len(scoreJSONs))

	for _, sJ := range scoreJSONs {
		scores = append(scores, game.Score(
			sJ,
		))
	}

	return scores
}

func toScoreJSONs(scores []game.Score) []scoreJSON {
	scoreJSONs := make([]scoreJSON, 0, len(scores))

	for _, s := range scores {
		scoreJSONs = append(scoreJSONs, scoreJSON(
			s,
		))
	}

	return scoreJSONs
}

func (p *SDL2Platform) GetScores() []game.Score {
	if !p.isScoresCacheValid {
		p.scoresCache = toGameScores(p.loadScoresJSON())
	}

	// We return a copy to permit mutation of the slice, without messing up
	// the cache.
	scores := make([]game.Score, len(p.scoresCache))
	copy(scores, p.scoresCache)

	return scores
}

func (p *SDL2Platform) loadScoresJSON() []scoreJSON {
	var scores []scoreJSON
	if p.config.saveFile != nil {
		if _, err := p.config.saveFile.Seek(0, 0); err != nil {
			fmt.Println(err)

			return scores
		}

		bytes, err := ioutil.ReadAll(p.config.saveFile)
		if err != nil {
			fmt.Println(err)

			return scores
		}

		// we expect this the first time the file is loaded
		if len(bytes) == 0 {
			fmt.Println("Previous save file was empty/non-existent")

			return scores
		}

		err = json.Unmarshal(bytes, &scores)

		if err != nil {
			fmt.Println(err)

			return scores
		}
	}

	return scores
}

func (p *SDL2Platform) SaveScores(scores []game.Score) {
	if p.config.saveFile == nil {
		return
	}

	bytes, err := json.Marshal(toScoreJSONs(scores))
	if err != nil {
		fmt.Println(err)

		return
	}

	if _, err = p.config.saveFile.Seek(0, 0); err != nil {
		fmt.Println(err)

		return
	}

	if err = p.config.saveFile.Truncate(0); err != nil {
		fmt.Println(err)

		return
	}

	if _, err = p.config.saveFile.Write(bytes); err != nil {
		fmt.Println(err)

		return
	}

	if err = p.config.saveFile.Sync(); err != nil {
		fmt.Println(err)
	}
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

type fonts struct {
	ui        *ttf.Font
	title     *ttf.Font
	scoreList *ttf.Font
	spellList *ttf.Font
}

type Assets struct {
	spritesheet *sdl.Texture
	fonts       fonts
	hit1        *mix.Chunk
	hit2        *mix.Chunk
	newLevel    *mix.Chunk
	spell       *mix.Chunk
	treasure    *mix.Chunk
}

func loadAssets(renderer *sdl.Renderer) Assets {
	//
	//  Images
	//

	spritesheetRW, err := sdl.RWFromMem(assets.Spritesheet)
	dieIfErr(err)

	spritesheet, err := img.LoadTextureRW(renderer, spritesheetRW, false)
	dieIfErr(err)

	//
	//  Fonts
	//

	fonts := loadFonts()

	//
	//  Audio
	//

	hit1RW, err := sdl.RWFromMem(assets.Hit1)
	dieIfErr(err)

	hit1, err := mix.LoadWAVRW(hit1RW, true)
	dieIfErr(err)

	hit2RW, err := sdl.RWFromMem(assets.Hit2)
	dieIfErr(err)

	hit2, err := mix.LoadWAVRW(hit2RW, true)
	dieIfErr(err)

	newLevelRW, err := sdl.RWFromMem(assets.NewLevel)
	dieIfErr(err)

	newLevel, err := mix.LoadWAVRW(newLevelRW, true)
	dieIfErr(err)

	spellRW, err := sdl.RWFromMem(assets.Spell)
	dieIfErr(err)

	spell, err := mix.LoadWAVRW(spellRW, true)
	dieIfErr(err)

	treasureRW, err := sdl.RWFromMem(assets.Treasure)
	dieIfErr(err)

	treasure, err := mix.LoadWAVRW(treasureRW, true)
	dieIfErr(err)

	return Assets{
		spritesheet,
		fonts,
		hit1,
		hit2,
		newLevel,
		spell,
		treasure,
	}
}

func loadFonts() fonts {
	// We get an error from SDL2 if we try to use the same RWOps for multiple fonts
	uiFontRW, err := sdl.RWFromMem(assets.Font)
	dieIfErr(err)

	uiFont, err := ttf.OpenFontRW(uiFontRW, 0, 40)
	dieIfErr(err)

	titleFontRW, err := sdl.RWFromMem(assets.Font)
	dieIfErr(err)

	titleFont, err := ttf.OpenFontRW(titleFontRW, 0, 70)
	dieIfErr(err)

	scoreListFontRW, err := sdl.RWFromMem(assets.Font)
	dieIfErr(err)

	scoreListFont, err := ttf.OpenFontRW(scoreListFontRW, 0, 24)
	dieIfErr(err)

	spellListFontRW, err := sdl.RWFromMem(assets.Font)
	dieIfErr(err)

	spellListFont, err := ttf.OpenFontRW(spellListFontRW, 0, 42)
	dieIfErr(err)

	return fonts{
		uiFont,
		titleFont,
		scoreListFont,
		spellListFont,
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
