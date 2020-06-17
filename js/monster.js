
class Monster{
	constructor(tile, sprite, hp){
        this.move(tile);
        this.sprite = sprite;
        this.hp = hp;
	}

	draw(){
        drawSprite(this.sprite, this.tile.x, this.tile.y);
	}

}
