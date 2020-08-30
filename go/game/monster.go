package game

type Monstrous interface {
}

type Monster struct {
	tileish Tileish
	sprite  SpriteIndex
	hp      HP
}

func NewMonster(tileish Tileish, sprite SpriteIndex, hp HP) Monster {
	return Monster{
		tileish,
		sprite,
		hp,
	}
}

func (m *Monster) draw(p Platform) {
	t := m.tileish.tile()
	p.Sprite(m.sprite, t.x, t.y)
}

func (m *Monster) tryMove(tiles *Tiles, dx, dy Delta) (moved bool) {
	newTileish := tiles.getNeighbor(m.tileish, dx, dy)
	newTile := newTileish.tile()
	if newTile.passable {
		if newTile.monster == nil {
			m.move(newTile)
		}
		moved = true
	}

	return
}

func (m *Monster) move(tileish Tileish) {
	if m.tileish != nil {
		m.tileish.tile().monster = nil
	}
	m.tileish = tileish
	m.tileish.tile().monster = m
}

type Player struct {
	Monster
}

func NewPlayer(tileish Tileish) *Player {
	return &Player{
		Monster: NewMonster(tileish, 0, 3),
	}
}
