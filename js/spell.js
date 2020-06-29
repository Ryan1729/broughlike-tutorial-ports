
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
    },
    DASH: function(){
        let newTile = player.tile;
        while(true){
            let testTile = newTile.getNeighbor(player.lastMove[0],player.lastMove[1]);
            if(testTile.passable && !testTile.monster){
                newTile = testTile;
            }else{
                break;
            }
        }
        if(player.tile != newTile){
            player.move(newTile);
            newTile.getAdjacentNeighbors().forEach(t => {
                if(t.monster){
                    t.setEffect(14);
                    t.monster.stunned = true;
                    t.monster.hit(1);
                }
            });
        }
    },
    DIG: function(){
        for(let i=1;i<numTiles-1;i++){
            for(let j=1;j<numTiles-1;j++){
                let tile = getTile(i,j);
                if(!tile.passable){
                    tile.replace(Floor);
                }
            }
        }
        player.tile.setEffect(13);
        player.heal(2);
    },
    KINGMAKER: function(){
        for(let i=0;i<monsters.length;i++){
            monsters[i].heal(1);
            monsters[i].tile.treasure = true;
        }
    },
    ALCHEMY: function(){
        player.tile.getAdjacentNeighbors().forEach(function(t){
            if(!t.passable && inBounds(t.x, t.y)){
                t.replace(Floor).treasure = true;
            }
        });
    },
    POWER: function(){
        player.bonusAttack=5;
    }
};
