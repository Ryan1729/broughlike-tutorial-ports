#![no_std]
#![deny(clippy::float_arithmetic)]

#[derive(Debug)]
#[non_exhaustive]
pub enum Error {
    TimeoutWhileTryingTo(&'static str),
    ExpectedNonPlayerToBePlayer(TileXY, MonsterKind),
    CouldNotFindPlayer(TileXY),
    OneIsZero
}

pub type Res<A> = Result<A, Error>;

pub type Level = core::num::NonZeroU8;

#[derive(Debug)]
pub struct State {
    pub xy: TileXY,
    rng: Xs,
    pub tiles: Tiles,
    pub level: Level,
}

pub type Seed = [u8; 16];

impl State {
    pub fn from_seed(mut seed: Seed) -> Res<Self> {
        // 0 doesn't work as a seed, so use this one instead.
        if seed == [0; 16] {
            seed = 0xBAD_5EED_u128.to_le_bytes();
        }

        macro_rules! wrap {
            ($i0: literal, $i1: literal, $i2: literal, $i3: literal) => {
                core::num::Wrapping(
                    u32::from_le_bytes([
                        seed[$i0],
                        seed[$i1],
                        seed[$i2],
                        seed[$i3],
                    ])
                )
            }
        }

        let mut rng: Xs = [
            wrap!( 0,  1,  2,  3),
            wrap!( 4,  5,  6,  7),
            wrap!( 8,  9, 10, 11),
            wrap!(12, 13, 14, 15),
        ];

        // I guess this is better than using unsafe?
        let level = Level::new(1).ok_or(Error::OneIsZero)?;

        let mut tiles = generate_level(&mut rng, level)?;

        random_passable_tile(&mut rng, &tiles).map(|t| {
            let player = Monster{
                xy: t.xy,
                hp: 3,
                ..Monster::default()
            };

            set_monster(&mut tiles, player);

            Self {
                xy: t.xy,
                rng,
                tiles,
                level,
            }   
        })
    }

    // When iterating monsters, We collect the monsters into a list
    // so that we don't hit the same monster twice in the iteration,
    // in case it moves
    pub fn get_monsters(&self) -> TileStack<Monster> {
        let mut monsters = TileStack::<Monster>::default();

        for y in 0..NUM_TILES {
            for x in 0..NUM_TILES {
                let xy = TileXY{ x, y };
                let t: Tile = self.tiles.get_tile(xy);
    
                if let Some(m) = t.monster {
                    monsters.push_saturating(m);
                }
            }
        }
    
        monsters
    }
}

type Xs = [core::num::Wrapping<u32>; 4];

fn xorshift(xs: &mut Xs) -> u32 {
    let mut t = xs[3];

    xs[3] = xs[2];
    xs[2] = xs[1];
    xs[1] = xs[0];

    t ^= t << 11;
    t ^= t >> 8;
    xs[0] = t ^ xs[0] ^ (xs[0] >> 19);

    xs[0].0
}

fn xs_u32(xs: &mut Xs, min: u32, one_past_max: u32) -> u32 {
    (xorshift(xs) % (one_past_max - min)) + min
}

pub type TileCount = u8;

/// The number of tiles across and tall that the grid is.
pub const NUM_TILES: TileCount = 9;

pub const UI_WIDTH: TileCount = 4;

pub type TileX = u8;
pub type TileY = u8;

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct TileXY {
    pub x: TileX,
    pub y: TileY,
}

macro_rules! txy {
    ($x: literal, $y: literal) => {
        TileXY {
            x: $x,
            y: $y,
        }
    };
    ($x: ident, $y: ident) => {
        TileXY {
            x: $x,
            y: $y,
        }
    };
}

// Manhattan distance
fn dist(txy!(x1, y1): TileXY, txy!(x2, y2): TileXY) -> TileCount {
    ((x1 as i8 - x2 as i8).abs() + (y1 as i8 - y2 as i8).abs()) as TileCount
}

// Should only be in the range [-1, 0, 1]
pub type DeltaX = i8;
// Should only be in the range [-1, 0, 1]
pub type DeltaY = i8;

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct DeltaXY {
    pub x: DeltaX,
    pub y: DeltaY,
}

macro_rules! dxy {
    ($x: literal, $y: literal) => {
        DeltaXY {
            x: $x,
            y: $y,
        }
    };
    ($x: ident, $y: ident) => {
        DeltaXY {
            x: $x,
            y: $y,
        }
    };
    ($x: expr, $y: expr) => {
        DeltaXY {
            x: $x,
            y: $y,
        }
    };
}

pub type SpriteIndex = u8;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TileKind {
    Wall,
    Floor,
}

impl Default for TileKind {
    fn default() -> Self {
        Self::Wall
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum MonsterKind {
    Player,
    Bird,
    Snake,
    Tank,
    Eater,
    Jester,
}

impl Default for MonsterKind {
    fn default() -> Self {
        Self::Player
    }
}

pub type HP = u8;
pub type Damage = u8;

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct Monster {
    pub xy: TileXY,
    pub kind: MonsterKind,
    pub hp: HP,
    pub attacked_this_turn: bool
}

fn make_bird(xy: TileXY) -> Monster {
    Monster {
        xy,
        kind: MonsterKind::Bird,
        hp: 3,
        ..Monster::default()
    }
}

fn make_snake(xy: TileXY) -> Monster {
    Monster {
        xy,
        kind: MonsterKind::Snake,
        hp: 1,
        ..Monster::default()
    }
}

fn make_tank(xy: TileXY) -> Monster {
    Monster {
        xy,
        kind: MonsterKind::Tank,
        hp: 2,
        ..Monster::default()
    }
}

fn make_eater(xy: TileXY) -> Monster {
    Monster {
        xy,
        kind: MonsterKind::Eater,
        hp: 1,
        ..Monster::default()
    }
}

fn make_jester(xy: TileXY) -> Monster {
    Monster {
        xy,
        kind: MonsterKind::Jester,
        hp: 2,
        ..Monster::default()
    }
}

impl Monster {
    fn is_dead(&self) -> bool {
        self.hp == 0
    }

    fn is_player(&self) -> bool {
        self.kind == MonsterKind::Player
    }

    fn hit(&self, damage: Damage) -> Monster {
        Monster {
            hp: self.hp.saturating_sub(damage),
            ..*self
        }
    }
}

fn remove_monster(tiles: &mut Tiles, xy: TileXY) {
    tiles.0[xy_to_i(xy)].monster = None;
}

fn set_monster(tiles: &mut Tiles, monster: Monster) {
    tiles.0[xy_to_i(monster.xy)].monster = Some(monster);
}

fn move_player(state: &mut State, dxy: DeltaXY) -> Res<()> {
    let tile = state.tiles.get_tile(state.xy);
    if let Some(monster) = tile.monster {
        if monster.kind == MonsterKind::Player {
            if let Some(moved) = try_move(state, monster, dxy) {
                state.xy = moved.xy;

                tick(state);
            }

            Ok(())
        } else {
            Err(Error::ExpectedNonPlayerToBePlayer(state.xy, monster.kind))
        }
    } else {
        Err(Error::CouldNotFindPlayer(state.xy))
    }
}

fn tick(state: &mut State) {
    let monsters = state.get_monsters();

    for monster in monsters.iter() {
        if monster.is_player() {
            continue;
        }

        if monster.is_dead() {
            remove_monster(&mut state.tiles, monster.xy);
        } else {
            update_monster(state, *monster);
        }
    }
}

fn try_move(state: &mut State, monster: Monster, dxy: DeltaXY) -> Option<Monster> {
    let new_tile = get_neighbor(&state.tiles, monster.xy, dxy);

    if new_tile.is_passable() {
        if let Some(target) = new_tile.monster {
            if monster.is_player() != target.is_player() {
                set_monster(&mut state.tiles, Monster{
                    attacked_this_turn: true,
                    ..monster
                });

                set_monster(&mut state.tiles, target.hit(1));
            };

            Some(monster)
        } else {
            Some(r#move(&mut state.tiles, monster, new_tile.xy))
        }
    } else {
        None
    }
}

fn r#move(tiles: &mut Tiles, monster: Monster, xy: TileXY) -> Monster {
    remove_monster(tiles, monster.xy);

    let mut moved = monster;
    moved.xy = xy;

    set_monster(tiles, moved);

    moved
}

fn update_monster(state: &mut State, mut monster: Monster) {
    match monster.kind {
        MonsterKind::Snake => {
            monster.attacked_this_turn = false;

            set_monster(&mut state.tiles, monster);

            if let Some(monster) = do_stuff(state, monster) {
                if !monster.attacked_this_turn {
                    do_stuff(state, monster);
                }
            }
        },
        _ => {
            do_stuff(state, monster);
        }
    }

    
}

fn do_stuff(state: &mut State, monster: Monster) -> Option<Monster> {
    let neighbors = get_adjacent_neighbors(
        &mut state.rng,
        &state.tiles,
        monster.xy
    );

    let mut filtered = neighbors.iter()
                        .filter(|t| t.is_passable())
                        .filter(|t|
                            t.monster.is_none() || t.monster.unwrap().is_player()
                        );

    let neighbors = [filtered.next(), filtered.next(), filtered.next(), filtered.next()];

    
    if let Some(Some(new_tile)) = neighbors.iter().min_by_key(|t|
        match t {
            Some(t) => dist(t.xy, state.xy),
            None => TileCount::MAX,
        }
    ) {
        try_move(
            state,
            monster,
            dxy!(
                new_tile.xy.x as DeltaX - monster.xy.x as DeltaX,
                new_tile.xy.y as DeltaY - monster.xy.y as DeltaY
            )
        )
    } else {
        None
    }
}

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct Tile {
    pub xy: TileXY,
    pub kind: TileKind,
    pub monster: Option<Monster>
}

impl Tile {
    fn is_passable(&self) -> bool {
        matches!(self.kind, TileKind::Floor)
    }
}

const TOTAL_TILE_COUNT: TileCount = NUM_TILES * NUM_TILES;

#[derive(Debug)]
pub struct Tiles([Tile; TOTAL_TILE_COUNT as _]);

fn make_wall(xy: TileXY) -> Tile {
    Tile {
        xy,
        kind: TileKind::Wall,
        ..<_>::default()
    }
}

fn make_floor(xy: TileXY) -> Tile {
    Tile {
        xy,
        kind: TileKind::Floor,
        ..<_>::default()
    }
}

impl Tiles {
    pub fn iter(&self) -> impl Iterator<Item = &Tile> {
        self.0.iter()
    }

    pub fn get_tile(&self, xy: TileXY) -> Tile {
        if in_bounds(xy) {
            self.0[xy_to_i(xy)]
        } else {
            make_wall(xy)
        }
    }
}

fn in_bounds(TileXY{x, y}: TileXY) -> bool {
    x > 0 && y > 0 && x < NUM_TILES-1 && y < NUM_TILES-1
}

fn xy_to_i(TileXY{x, y}: TileXY) -> usize {
    (y * NUM_TILES + x) as _
}

fn generate_level(rng: &mut Xs, level: Level) -> Res<Tiles> {
    let mut tiles = try_to(
        "generate map",
        || {
            let (tiles, passable_count) = generate_tiles(rng);

            let reachable_count = random_passable_tile(rng, &tiles)
                .map(|t| {
                    get_connected_tiles(rng, &tiles, t).length
                }).map_err(|_| ())?;

            if reachable_count == passable_count{
                Ok(tiles)
            } else {
                Err(())
            }
        }
    )?;

    generate_monsters(rng, &mut tiles, level);

    Ok(tiles)
}

fn generate_tiles(rng: &mut Xs) -> (Tiles, TileCount) {
    let mut tiles = [Tile::default(); TOTAL_TILE_COUNT as _];

    let mut passable_tiles = 0;

    for y in 0..NUM_TILES {
        for x in 0..NUM_TILES {
            let xy = TileXY{ x, y };
            let i = xy_to_i(xy);

            if !in_bounds(xy) || xs_u32(rng, 0, 10) < 3 {
                tiles[i] = make_wall(xy);
            }else{
                tiles[i] = make_floor(xy);

                passable_tiles += 1;
            }
        }
    }

    (Tiles(tiles), passable_tiles)
}

fn generate_monsters(rng: &mut Xs, tiles: &mut Tiles, level: Level) {
    for _ in 0..level.get() + 1 {
        spawn_monster(rng, tiles);
    }
}

fn spawn_monster(rng: &mut Xs, tiles: &mut Tiles) {
    // The player won't mind if a monster doesn't spawn.
    if let Ok(tile) = random_passable_tile(rng, tiles) {
        let mut makers = [make_bird, make_snake, make_tank, make_eater, make_jester];
        shuffle(rng, &mut makers);

        let monster = makers[0](tile.xy);
    
        set_monster(tiles, monster);
    }
}

#[derive(Clone)]
pub struct TileStack<A = Tile> {
    pool: [A; TOTAL_TILE_COUNT as _],
    length: TileCount,
}

impl <A: Default + Copy> Default for TileStack<A> {
    fn default() -> Self {
        Self {
            pool: [A::default(); TOTAL_TILE_COUNT as _],
            length: 0,
        }
    }
}

impl <A> TileStack<A> {
    fn push_saturating(&mut self, a: A) {
        if self.length as usize >= self.pool.len() {
            debug_assert!(
                !(self.length as usize >= self.pool.len()),
                "TileStack overflow!"
            );
            return;
        }

        self.pool[self.length as usize] = a;
        self.length += 1;
    }

    pub fn iter(&self) -> impl Iterator<Item = &A> {
        self.pool.iter().take(self.length as _)
    }
}

fn get_connected_tiles(rng: &mut Xs, tiles: &Tiles, tile: Tile) -> TileStack {
    let mut connected = TileStack::default();

    connected.push_saturating(tile);

    let mut frontier = connected.clone();

    while frontier.length > 0 {
        // We currently know frontier.length > 0
        let popped: Tile = frontier.pool[frontier.length as usize - 1];
        frontier.length -= 1;

        let neighbors = get_adjacent_neighbors(rng, tiles, popped.xy);

        let mut filtered = neighbors.iter()
                            .filter(|t| t.is_passable())
                            .filter(|n|
                                !connected.iter().any(|c| c == *n)
                            );
        let filtered = [filtered.next(), filtered.next(), filtered.next(), filtered.next()];

        for tile in filtered.iter() {
            if let Some(&t) = tile {
                connected.push_saturating(t);
                frontier.push_saturating(t);
            }        
        }
    }

    connected
}

fn get_adjacent_neighbors(
    rng: &mut Xs,
    tiles: &Tiles,
    xy: TileXY
) -> [Tile; 4] {
    let mut neighbors = [
        get_neighbor(tiles, xy, dxy!(0, -1)),
        get_neighbor(tiles, xy, dxy!(0, 1)),
        get_neighbor(tiles, xy, dxy!(-1, 0)),
        get_neighbor(tiles, xy, dxy!(1, 0))
    ];

    shuffle(rng, &mut neighbors);

    neighbors
}

fn shuffle<A>(rng: &mut Xs, slice: &mut [A]) {
    for i in 1..slice.len() as u32 {
        // This only shuffles the first u32::MAX_VALUE - 1 elements.
        let r = xs_u32(rng, 0, i + 1) as usize;
        let i = i as usize;
        slice.swap(i, r);
    }
}

fn get_neighbor(
    tiles: &Tiles,
    TileXY{x, y}: TileXY,
    dxy!{dx, dy}: DeltaXY,
) -> Tile {
    tiles.get_tile(
        TileXY {
            x: (x as DeltaX + dx) as TileX,
            y: (y as DeltaY + dy) as TileY,
        }
    )
}

fn random_passable_tile(rng: &mut Xs, tiles: &Tiles) -> Res<Tile> {
    try_to(
        "get random passable tile",
        || {
            use core::convert::TryInto;
            let x = xs_u32(rng, 0, (NUM_TILES).into()).try_into().map_err(|_| ())?;
            let y = xs_u32(rng, 0, (NUM_TILES).into()).try_into().map_err(|_| ())?;
            let tile = Tiles::get_tile(tiles, TileXY{x, y});
            if tile.is_passable() && tile.monster.is_none(){
                Ok(tile)
            } else {
                Err(())
            }
        }
    )
}

fn try_to<Out, F>(description: &'static str, mut callback: F) -> Res<Out>
where 
    F: FnMut() -> Result<Out, ()> {

    for _ in 0..1000 {
        if let Ok(out) = callback() {
            return Ok(out);
        }
    }

    Err(Error::TimeoutWhileTryingTo(description))
}

#[derive(Copy, Clone)]
pub enum Input {
    Empty,
    Up,
    Down,
    Left,
    Right,
}

pub fn update(state: &mut State, input: Input) -> Res<()> {
    use Input::*;

    match input {
        Empty => {
            Ok(())
        },
        Up => {
            move_player(state, dxy!(0, -1))
        },
        Down => {
            move_player(state, dxy!(0, 1))
        },
        Left => {
            move_player(state, dxy!(-1, 0))
        },
        Right => {
            move_player(state, dxy!(1, 0))
        },
    }
}