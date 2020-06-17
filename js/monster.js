
class Monster{
	constructor(tile, sprite, hp){
        this.move(tile);
        this.sprite = sprite;
        this.hp = hp;
	}

	draw(){
        drawSprite(this.sprite, this.tile.x, this.tile.y);
	}


    tryMove(dx, dy){
        let newTile = this.tile.getNeighbor(dx,dy);
        if(newTile.passable){
            if(!newTile.monster){
                this.move(newTile);
            }
            return true;
        }
    }

    move(tile){
        if(this.tile){
            this.tile.monster = null;
        }
        this.tile = tile;
        tile.monster = this;
    }
}

class Player extends Monster{
    constructor(tile){
        super(tile, 0, 3);
        this.isPlayer = true;
    }
}

class Bird extends Monster{
    constructor(tile){
        super(tile, 4, 3);
    }
}

class Snake extends Monster{
    constructor(tile){
        super(tile, 5, 1);
    }
}

class Tank extends Monster{
    constructor(tile){
        super(tile, 6, 2);
    }
}

class Eater extends Monster{
    constructor(tile){
        super(tile, 7, 1);
    }
}

class Jester extends Monster{
    constructor(tile){
        super(tile, 8, 2);
    }
}
