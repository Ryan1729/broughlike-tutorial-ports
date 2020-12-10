
from monster import Monster
from tile import Tile

type    
  TileAndMonster = tuple[tile: var Tile, monster: Monster]

{.push warning[ProveInit]: off .}
proc getPairsSeq*(): seq[TileAndMonster] =
    newSeqOfCap[TileAndMonster](map.tileLen)
{.pop.}
