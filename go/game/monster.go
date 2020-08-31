package game

type Monstrous interface {
	draw(p Platform)
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
