package game

import (
	"math"
	"sort"
)

const (
	healthSize = 5.0 * OneOverSubTileUnit
)

type Monstrous interface {
	monster() *Monster
	draw(p Platform)
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
		m.tileish.tile().monster = nil
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
				monstrous.monster().attackedThisTurn = true
				nTM := newTile.monster.monster()
				nTM.stunned = true
				nTM.hit(1)
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

type Monster struct {
	tileish          Tileish
	hp               HP
	sprite           SpriteIndex
	teleportCounter  counter
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
		tileish,
		hp,
		sprite,
		counter{2},
		false,
		false,
		false,
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

func (m *Monster) hit(damage HP) {
	m.hp -= damage
	if m.hp <= 0 {
		m.die()
	}
}

func (m *Monster) die() {
	m.dead = true
	m.tileish.tile().monster = nil
	m.sprite = 1
}

func (m *Monster) draw(p Platform) {
	t := m.tileish.tile()

	if m.teleportCounter.isActive() {
		sprite(p, 10, t.x, t.y)
	} else {
		sprite(p, m.sprite, t.x, t.y)
		m.drawHp(p)
	}
}

func (m *Monster) drawHp(p Platform) {
	tile := m.tileish.tile()
	var i HP
	for ; i < m.hp; i++ {
		p.SubTileSprite(
			9,
			SubTilePosition(tile.x)+SubTilePosition(math.Mod(float64(i), 3.0))*healthSize,
			SubTilePosition(tile.y)-SubTilePosition(math.Floor(float64(i)/3.0))*healthSize,
		)
	}
}

type MonsterMaker = func(tileish Tileish) Monstrous

type Player struct {
	*Monster
}

func NewPlayer(tileish Tileish) Monstrous {
	return NewPlayerStruct(tileish)
}

func NewPlayerStruct(tileish Tileish) *Player {
	m := NewMonster(tileish, 0, 3)
	m.teleportCounter = counter{0}

	return &Player{
		Monster: m,
	}
}

func (p *Player) tryMove(platform Platform, s *State, dx, dy Delta) error {
	moved, err := tryMove(platform, s, p, dx, dy)
	if err != nil {
		return err
	}

	if moved {
		return tick(platform, s)
	}

	return nil
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
