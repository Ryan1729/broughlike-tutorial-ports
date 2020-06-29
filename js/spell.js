
spells = {
    WOOP: function(){
        player.move(randomPassableTile());
    },
    QUAKE: function(){
        for(let i=0; i<numTiles; i++){
            for(let j=0; j<numTiles; j++){
                let tile = getTile(i,j);
                if(tile.monster){
                    let numWalls = 4 - tile.getAdjacentPassableNeighbors().length;
                    tile.monster.hit(numWalls*2);
                }
            }
        }
        shakeAmount = 20;
    },
    MAELSTROM: function(){
        for(let i=0;i<monsters.length;i++){
            monsters[i].move(randomPassableTile());
            monsters[i].teleportCounter = 2;
        }
    },
    MULLIGAN: function(){
        startLevel(1, player.spells);
    },
    AURA: function(){
        player.tile.getAdjacentNeighbors().forEach(function(t){
            t.setEffect(13);
            if(t.monster){
                t.monster.heal(1);
            }
        });
        player.tile.setEffect(13);
        player.heal(1);
    }
};
