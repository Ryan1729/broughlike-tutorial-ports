package game

import (
	"sort"
)

const (
	healthSize = 5.0 / 16.0
)

type Monstrous interface {
	monster() *Monster
	draw(p Platform)
	update(s *State)
}

// It's important that this is implemented as is, instead of say a method on
// *Monster, because we assign the "this" to the passed in tile's monster
// property, and we want to store the entire Monstrous implementor there.
func move(monstrous Monstrous, tileish Tileish) {
	m := monstrous.monster()
	if m.tileish != nil {
		m.tileish.tile().monster = nil
	}
	m.tileish = tileish
	m.tileish.tile().monster = monstrous
}

func tryMove(monstrous Monstrous, tiles *Tiles, dx, dy Delta) (moved bool) {
	newTileish := tiles.getNeighbor(monstrous.monster().tileish, dx, dy)
	newTile := newTileish.tile()
	if newTile.passable {
		if newTile.monster == nil {
			move(monstrous, newTile)
		} else {
			_, mIsPlayer := monstrous.(*Player)
			_, nTIsPlayer := newTile.monster.(*Player)
			if mIsPlayer != nTIsPlayer {
				newTile.monster.monster().hit(1)
			}
		}
		moved = true
	}

	return
}

type Monster struct {
	tileish Tileish
	sprite  SpriteIndex
	hp      HP
	dead    bool
}

func NewMonster(tileish Tileish, sprite SpriteIndex, hp HP) Monster {
	m := Monster{
		tileish,
		sprite,
		hp,
		false,
	}

	move(&m, tileish)

	return m
}

func (m *Monster) monster() *Monster {
	return m
}

func (m *Monster) update(s *State) {
	m.doStuff(s)
}

func (m *Monster) doStuff(s *State) {
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
		tryMove(m, &s.tiles, Delta(newTile.x)-Delta(tile.x), Delta(newTile.y)-Delta(tile.y))
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
	sprite(p, m.sprite, t.x, t.y)

	m.drawHp(p)
}

func (m *Monster) drawHp(p Platform) {
	tile := m.tileish.tile()
	var i HP
	for ; i < m.hp; i++ {
		p.SubTileSprite(
			9,
			SubTilePosition(tile.x)+SubTilePosition(i%3)*healthSize,
			SubTilePosition(tile.y)-SubTilePosition(i/3)*healthSize,
		)
	}
}

type MonsterMaker = func(tileish Tileish) Monstrous

type Player struct {
	Monster
}

func NewPlayer(tileish Tileish) Monstrous {
	return NewPlayerStruct(tileish)
}

func NewPlayerStruct(tileish Tileish) *Player {
	return &Player{
		Monster: NewMonster(tileish, 0, 3),
	}
}

func (p *Player) tryMove(s *State, dx, dy Delta) {
	if tryMove(p, &s.tiles, dx, dy) {
		tick(s)
	}
}

type Bird struct {
	Monster
}

func NewBird(tileish Tileish) Monstrous {
	return &Bird{
		Monster: NewMonster(tileish, 4, 3),
	}
}

type Snake struct {
	Monster
}

func NewSnake(tileish Tileish) Monstrous {
	return &Snake{
		Monster: NewMonster(tileish, 5, 1),
	}
}

type Tank struct {
	Monster
}

func NewTank(tileish Tileish) Monstrous {
	return &Tank{
		Monster: NewMonster(tileish, 6, 2),
	}
}

type Eater struct {
	Monster
}

func NewEater(tileish Tileish) Monstrous {
	return &Eater{
		Monster: NewMonster(tileish, 7, 1),
	}
}

type Jester struct {
	Monster
}

func NewJester(tileish Tileish) Monstrous {
	return &Jester{
		Monster: NewMonster(tileish, 8, 2),
	}
}
