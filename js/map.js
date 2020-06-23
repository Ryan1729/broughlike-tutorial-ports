function generateLevel(){
    generateTiles();
}

function generateTiles(){
    tiles = [];
    for(let i=0;i<numTiles;i++){
        tiles[i] = [];
        for(let j=0;j<numTiles;j++){
            if(Math.random() < 0.3 || !inBounds(i,j)){
                tiles[i][j] = new Wall(i,j);
            }else{
                tiles[i][j] = new Floor(i,j);
            }
        }
    }
}

function inBounds(x,y){
    return x>0 && y>0 && x<numTiles-1 && y<numTiles-1;
}

function getTile(x, y){
    if(inBounds(x,y)){
        return tiles[x][y];
    }else{
        return new Wall(x,y);
    }
}