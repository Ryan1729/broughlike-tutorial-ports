class Tile{
	constructor(x, y, sprite, passable){
        this.x = x;
        this.y = y;
        this.sprite = sprite;
        this.passable = passable;
	}

	draw(){
        drawSprite(this.sprite, this.x, this.y);
	}
}

class Floor extends Tile{
    constructor(x,y){
        super(x, y, 2, true);
    };
}

class Wall extends Tile{
    constructor(x, y){
        super(x, y, 3, false);
    }
}