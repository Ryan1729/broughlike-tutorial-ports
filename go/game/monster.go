package game

import (
	"math"
	"sort"
)

const (
	healthSize          = 5.0 * OneOverSubTileUnit
	slideAmountPerFrame = 2.0 * OneOverSubTileUnit
)

type Monstrous interface {
	monster() *Monster
	draw(p Platform, shake shake)
	update(p Platform, s *State) error
	doStuff(p Platform, s *State) error
}

// It's important that this is implemented as is, instead of say a method on
// *Monster, because we assign the "this" to the passed in tile's monster
// property, and we want to store the entire Monstrous implementor there.
func move(p Platform, s *State, monstrous Monstrous, tileish Tileish) error {
	moveWithoutStepOn(monstrous, tileish)

	return monstrous.monster().tileish.stepOn(p, s, monstrous)
}

func moveWithoutStepOn(monstrous Monstrous, tileish Tileish) {
	m := monstrous.monster()
	if m.tileish != nil {
		tile := tileish.tile()
		mTile := m.tileish.tile()
		mTile.monster = nil
		m.offsetX = SubTilePosition(mTile.x) - SubTilePosition(tile.x)
		m.offsetY = SubTilePosition(mTile.y) - SubTilePosition(tile.y)
	}
	m.tileish = tileish
	m.tileish.tile().monster = monstrous
}

func tryMove(p Platform, s *State, monstrous Monstrous, dx, dy Delta) (moved bool, err error) {
	newTileish := s.tiles.getNeighbor(monstrous.monster().tileish, dx, dy)
	newTile := newTileish.tile()
	if newTile.passable {
		if newTile.monster == nil {
			err = move(p, s, monstrous, newTileish)
		} else {
			_, mIsPlayer := monstrous.(*Player)
			_, nTIsPlayer := newTile.monster.(*Player)
			if mIsPlayer != nTIsPlayer {
				m := monstrous.monster()
				m.attackedThisTurn = true
				nTM := newTile.monster.monster()
				nTM.stunned = true
				hit(p, newTile.monster, 1+m.bonusAttack)
				m.bonusAttack = 0

				s.shake.amount = counter{5}

				m.offsetX = (SubTilePosition(newTile.x) - SubTilePosition(m.tileish.tile().x)) / 2
				m.offsetY = (SubTilePosition(newTile.y) - SubTilePosition(m.tileish.tile().y)) / 2
			}
		}
		moved = true
	}

	return
}

func doStuffUnlessStunned(monstrous Monstrous, p Platform, s *State) error {
	m := monstrous.monster()

	m.teleportCounter.dec()

	if m.stunned || m.teleportCounter.isActive() {
		m.stunned = false

		return nil
	}

	return monstrous.doStuff(p, s)
}

func hit(p Platform, monstrous Monstrous, damage HP) {
	m := monstrous.monster()

	if m.shield.isActive() {
		return
	}

	m.hp -= damage
	if m.hp <= 0 {
		m.die()
	}

	if _, mIsPlayer := monstrous.(*Player); mIsPlayer {
		p.Sound(Hit1)
	} else {
		p.Sound(Hit2)
	}
}

type Monster struct {
	tileish          Tileish
	offsetX          SubTilePosition
	offsetY          SubTilePosition
	hp               HP
	sprite           SpriteIndex
	teleportCounter  counter
	bonusAttack      HP
	shield           counter
	dead             bool
	attackedThisTurn bool
	stunned          bool
}

// NewMonster returns a pointer to a monster which has a pointer to itself inside itself, via the tileish field.
// This means that the Monster value must not be copied, since then the new struct would be pointing toi the old
// struct! Copying and/or storing the pointer is fine, just don't and save the value you get from dereferencing
// it, anywhere.
func NewMonster(tileish Tileish, sprite SpriteIndex, hp HP) *Monster {
	m := &Monster{
		tileish:         tileish,
		hp:              hp,
		sprite:          sprite,
		teleportCounter: counter{2},
	}

	moveWithoutStepOn(m, tileish)

	return m
}

func (m *Monster) monster() *Monster {
	return m
}

func (m *Monster) update(p Platform, s *State) error {
	return doStuffUnlessStunned(m, p, s)
}

func (m *Monster) doStuff(p Platform, s *State) error {
	neighbors := s.tiles.getAdjacentPassableNeighbors(m.tileish)

	neighbors = filter(neighbors, func(t Tileish) bool {
		switch t.tile().monster.(type) {
		case nil:
			return true
		case *Player:
			return true
		default:
			return false
		}
	})

	if len(neighbors) > 0 {
		playerTile := s.player.Monster.tileish
		sort.Slice(neighbors, func(aIndex, bIndex int) bool {
			return neighbors[aIndex].dist(playerTile) < neighbors[bIndex].dist(playerTile)
		})
		newTile := neighbors[0].tile()
		tile := m.tileish.tile()

		_, err := tryMove(p, s, m, Delta(newTile.x)-Delta(tile.x), Delta(newTile.y)-Delta(tile.y))

		return err
	}

	return nil
}

func (m *Monster) heal(damage HP) {
	m.hp += damage
	if m.hp > maxHP {
		m.hp = maxHP
	}
}

func (m *Monster) die() {
	m.dead = true
	m.tileish.tile().monster = nil
	m.sprite = 1
}

func (m *Monster) getDisplayX() SubTilePosition {
	return SubTilePosition(m.tileish.tile().x) + m.offsetX
}

func (m *Monster) getDisplayY() SubTilePosition {
	return SubTilePosition(m.tileish.tile().y) + m.offsetY
}

func (m *Monster) draw(p Platform, shake shake) {
	if m.teleportCounter.isActive() {
		subTileSprite(
			p,
			10,
			m.getDisplayX(),
			m.getDisplayY(),
			shake,
		)
	} else {
		subTileSprite(
			p,
			m.sprite,
			m.getDisplayX(),
			m.getDisplayY(),
			shake,
		)
		m.drawHp(p, shake)
	}

	m.offsetX -= signum(m.offsetX) * slideAmountPerFrame
	m.offsetY -= signum(m.offsetY) * slideAmountPerFrame
}

func signum(stp SubTilePosition) SubTilePosition {
	switch {
	case stp > 0:
		return 1.0
	case stp < 0:
		return -1.0
	default:
		// NaN ends up here
		return 0.0
	}
}

func (m *Monster) drawHp(p Platform, shake shake) {
	var i HP
	for ; i < m.hp; i++ {
		subTileSprite(
			p,
			9,
			m.getDisplayX()+
				SubTilePosition(math.Mod(float64(i), 3.0))*healthSize,
			m.getDisplayY()-
				SubTilePosition(math.Floor(float64(i)/3.0))*healthSize,
			shake,
		)
	}
}

type MonsterMaker = func(tileish Tileish) Monstrous

type Player struct {
	*Monster
	spells   []SpellName
	lastMove [2]Delta
}

func NewPlayerStruct(s *State, tileish Tileish) *Player {
	m := NewMonster(tileish, 0, 3)
	m.teleportCounter = counter{0}

	spellNames := shuffledSpellNames(s.spells)
	maxSpells := int(s.numSpells)
	if maxSpells > len(spellNames) {
		maxSpells = len(spellNames)
	}

	playerSpells := spellNames[:maxSpells]

	return &Player{
		Monster:  m,
		spells:   playerSpells,
		lastMove: [2]Delta{-1, 0},
	}
}

func (p *Player) update(platform Platform, s *State) error {
	p.shield.dec()

	return nil
}

func (p *Player) tryMove(platform Platform, s *State, dx, dy Delta) error {
	moved, err := tryMove(platform, s, p, dx, dy)
	if err != nil {
		return err
	}

	if moved {
		p.lastMove = [2]Delta{dx, dy}

		return tick(platform, s)
	}

	return nil
}

func (p *Player) addSpell(spells SpellMap) {
	p.spells = append(p.spells, shuffledSpellNames(spells)[0])
}

func (p *Player) castSpell(platform Platform, s *State, index int) (err error) {
	spellName := NoSpell
	if index >= 0 && index < len(p.spells) {
		spellName = p.spells[index]
	}

	if spellName != NoSpell {
		p.spells[index] = NoSpell
		err = s.spells[spellName](platform, s)
		if err != nil {
			return err
		}

		platform.Sound(SpellSound)
		err = tick(platform, s)
		if err != nil {
			return err
		}
	}

	return err
}

type Bird struct {
	*Monster
}

func NewBird(tileish Tileish) Monstrous {
	return &Bird{
		Monster: NewMonster(tileish, 4, 3),
	}
}

type Snake struct {
	*Monster
}

func NewSnake(tileish Tileish) Monstrous {
	return &Snake{
		Monster: NewMonster(tileish, 5, 1),
	}
}

func (m *Snake) update(p Platform, s *State) error {
	return doStuffUnlessStunned(m, p, s)
}

func (m *Snake) doStuff(p Platform, s *State) error {
	m.Monster.attackedThisTurn = false
	err := m.Monster.doStuff(p, s)
	if err != nil {
		return err
	}

	if !m.Monster.attackedThisTurn {
		return m.Monster.doStuff(p, s)
	}

	return nil
}

type Tank struct {
	*Monster
}

func NewTank(tileish Tileish) Monstrous {
	return &Tank{
		Monster: NewMonster(tileish, 6, 2),
	}
}

func (m *Tank) update(p Platform, s *State) error {
	startedStunned := m.monster().stunned

	err := doStuffUnlessStunned(m, p, s)
	if err != nil {
		return err
	}

	if !startedStunned {
		m.monster().stunned = true
	}

	return nil
}

type Eater struct {
	*Monster
}

func NewEater(tileish Tileish) Monstrous {
	return &Eater{
		Monster: NewMonster(tileish, 7, 1),
	}
}

func (m *Eater) update(p Platform, s *State) error {
	return doStuffUnlessStunned(m, p, s)
}

func (m *Eater) doStuff(p Platform, s *State) error {
	neighbors := filter(
		s.tiles.getAdjacentNeighbors(m.monster().tileish),
		func(tileish Tileish) bool {
			t := tileish.tile()

			return !t.passable && inBounds(t.x, t.y)
		},
	)
	if len(neighbors) > 0 {
		s.tiles.replace(neighbors[0], NewFloor)
		m.heal(0.5)
	} else {
		return m.Monster.doStuff(p, s)
	}

	return nil
}

type Jester struct {
	*Monster
}

func NewJester(tileish Tileish) Monstrous {
	return &Jester{
		Monster: NewMonster(tileish, 8, 2),
	}
}

func (m *Jester) update(p Platform, s *State) error {
	return doStuffUnlessStunned(m, p, s)
}

func (m *Jester) doStuff(p Platform, s *State) (err error) {
	tileish := m.monster().tileish
	neighbors := s.tiles.getAdjacentPassableNeighbors(tileish)
	if len(neighbors) > 0 {
		t := tileish.tile()
		_, err = tryMove(
			p,
			s,
			m,
			Delta(neighbors[0].tile().x-t.x),
			Delta(neighbors[0].tile().y-t.y),
		)
	}

	return
}
