package game

type Monstrous interface {
	monster() *Monster
	draw(p Platform)
}

// It's important that this is implemented as is, instead of say a metho on
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
		}
		moved = true
	}

	return
}

type Monster struct {
	tileish Tileish
	sprite  SpriteIndex
	hp      HP
}

func NewMonster(tileish Tileish, sprite SpriteIndex, hp HP) Monster {
	m := Monster{
		tileish,
		sprite,
		hp,
	}

	move(&m, tileish)

	return m
}

func (m *Monster) monster() *Monster {
	return m
}

		}
	}
}

func (m *Monster) draw(p Platform) {
	t := m.tileish.tile()
	p.Sprite(m.sprite, t.x, t.y)
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
