#![no_std]
#![deny(clippy::float_arithmetic)]

#[derive(Debug)]
#[non_exhaustive]
pub enum Error {
    TimeoutWhileTryingTo(&'static str),
    ExpectedNonPlayerToBePlayer(TileXY, MonsterKind),
    CouldNotFindPlayer(TileXY),
    AlreadyAtTitle,
    ZombiePlayer,
}

pub type Res<A> = Result<A, Error>;

pub type Level = u8;
const NUM_LEVELS: Level = 6;

#[derive(Debug)]
pub enum State {
    TitleFirst(Seed),
    TitleReturn(World),
    Running(World),
    Dead(World),
    Error(Error)
}

pub type Seed = [u8; 16];

impl State {
    fn from_seed(seed: Seed) -> Self {
        match World::from_seed(seed, 1, None, None, None, [SoundSpec::NoSound; 16]) {
            Ok(w) => Self::Running(w),
            Err(e) => Self::Error(e),
        }
    }
}

type Counter = u8;
type SpawnRate = u8;

#[derive(Debug)]
pub struct Spawn {
    counter: Counter,
    rate: SpawnRate,
}

// 64k points ought to be enough for anybody.
pub type Score = u16;

pub type Amount = u8;

#[derive(Debug)]
pub struct Shake {
    pub amount: Amount,
    pub xy: OffsetXY,
    // We keep a separate shake RNG so that how fast the user inputs things
    // does not affect the world generation
    rng: Xs,
}

#[derive(Clone, Copy, Debug)]
pub enum SoundSpec {
    NoSound,
    PlayerWasHit,
    NonPlayerWasHit,
    Treasure,
    NewLevel,
    Spell,
}

#[derive(Debug)]
pub struct World {
    pub sound_specs: [SoundSpec; 16],
    pub xy: TileXY,
    rng: Xs,
    pub tiles: Tiles,
    pub spells: SpellBook,
    pub num_spells: SpellCount,
    pub spawn: Spawn,
    pub score: Score,
    pub level: Level,
    pub shake: Shake,
}

impl World {
    fn from_seed(
        mut seed: Seed,
        level: Level,
        starting_hp: Option<HP>,
        starting_score: Option<Score>,
        num_spells: Option<SpellCount>,
        sound_specs: [SoundSpec; 16]
    ) -> Res<Self> {
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

        let mut tiles = generate_level(&mut rng, level)?;

        random_passable_tile(&mut rng, &tiles).and_then(|exit_tile| {
            random_passable_tile(&mut rng, &tiles).map(|player_tile| {
                // Do the exit first so we don't remove the player!
                replace(&mut tiles, exit_tile.xy, make_exit);
    
                let mut player = Monster{
                    xy: player_tile.xy,
                    hp: hp!(3),
                    ..Monster::default()
                };
    
                if let Some(hp) = starting_hp {
                    player.hp = hp;
                }
    
                set_monster(&mut tiles, player);

                let rate = 15;

                for _ in 0..3 {
                    // The player presumably wouldn't mind missing treasure as much
                    // as say, a missing exit.
                    if let Ok(Tile{xy, ..}) = random_passable_tile(&mut rng, &tiles) {
                        set_treasure(&mut tiles, xy, true);
                    }
                }

                let num_spells = num_spells.unwrap_or(1);

                let mut all_spells = ALL_SPELL_NAMES.clone();
                shuffle(&mut rng, &mut all_spells);

                let mut spells = [None; MAX_NUM_SPELLS as usize];
                for i in 0..num_spells as usize {
                    spells[i] = Some(all_spells[i]);
                }

                Self {
                    sound_specs,
                    xy: player_tile.xy,
                    rng,
                    tiles,
                    level,
                    spawn: Spawn {
                        counter: rate,
                        rate,
                    },
                    score: starting_score.unwrap_or_default(),
                    shake: Shake {
                        amount: 0,
                        xy: OffsetXY::default(),
                        // We keep a separate shake RNG so that how fast the user inputs things
                        // does not affect the world generation
                        rng,
                    },
                    num_spells,
                    spells,
                }   
            })
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

    fn clear_sounds(&mut self) {
        self.sound_specs = [SoundSpec::NoSound; 16];
    }

    fn push_sound(&mut self, spec: SoundSpec) {
        for i in 0..self.sound_specs.len() {
            if let SoundSpec::NoSound = self.sound_specs[i] {
               self.sound_specs[i] = spec;
                break;
            }
            // Note that if we run out of sounds, we just don't push it on.
        }
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

fn new_seed(rng: &mut Xs) -> Seed {
    let s0 = xorshift(rng).to_le_bytes();
    let s1 = xorshift(rng).to_le_bytes();
    let s2 = xorshift(rng).to_le_bytes();
    let s3 = xorshift(rng).to_le_bytes();

    [
        s0[0], s0[1], s0[2], s0[3],
        s1[0], s1[1], s1[2], s1[3],
        s2[0], s2[1], s2[2], s2[3],
        s3[0], s3[1], s3[2], s3[3],
    ]
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
    Exit,
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

type HPRaw = u8;

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, PartialOrd, Ord)]
pub struct HP {
    pub use_the_macro_instead: HPRaw
}

#[macro_export]
macro_rules! hp {
    (get $hp: expr) => { $hp.use_the_macro_instead };
    (get pips $hp: expr) => { ($hp.use_the_macro_instead + 1) / 2 };
    (0) => { hp!(raw 0) };
    (0.5) => { hp!(raw 1) };
    (1) => { hp!(raw 2) };
    (2) => { hp!(raw 4) };
    (3) => { hp!(raw 6) };
    (raw $hp: expr) => { $crate::HP { use_the_macro_instead: $hp } };
}

impl HP {
    const MAX: HPRaw = 12;

    fn saturating_add(&self, hp: HP) -> HP {
        let added = hp!(get self).saturating_add(hp!(get hp));

        hp!(raw if added > Self::MAX {
            Self::MAX
        } else {
            added
        })
    }

    fn saturating_sub(&self, hp: HP) -> HP {
        hp!(raw hp!(get self).saturating_sub(hp!(get hp)))
    }
}

pub type OffsetX = i16;
pub type OffsetY = i16;

pub const OFFSET_MULTIPLE: i16 = 8;

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct OffsetXY {
    pub x: OffsetX,
    pub y: OffsetY,
}

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct Monster {
    pub xy: TileXY,
    pub kind: MonsterKind,
    pub hp: HP,
    pub attacked_this_turn: bool,
    pub stunned: bool,
    pub teleport_counter: Counter,
    pub offset_xy: OffsetXY,
}

const MONSTER_COUNTER_START: Counter = 2;

fn make_bird(xy: TileXY) -> Monster {
    Monster {
        xy,
        kind: MonsterKind::Bird,
        hp: hp!(3),
        teleport_counter: MONSTER_COUNTER_START,
        ..Monster::default()
    }
}

fn make_snake(xy: TileXY) -> Monster {
    Monster {
        xy,
        kind: MonsterKind::Snake,
        hp: hp!(1),
        teleport_counter: MONSTER_COUNTER_START,
        ..Monster::default()
    }
}

fn make_tank(xy: TileXY) -> Monster {
    Monster {
        xy,
        kind: MonsterKind::Tank,
        hp: hp!(2),
        teleport_counter: MONSTER_COUNTER_START,
        ..Monster::default()
    }
}

fn make_eater(xy: TileXY) -> Monster {
    Monster {
        xy,
        kind: MonsterKind::Eater,
        hp: hp!(1),
        teleport_counter: MONSTER_COUNTER_START,
        ..Monster::default()
    }
}

fn make_jester(xy: TileXY) -> Monster {
    Monster {
        xy,
        kind: MonsterKind::Jester,
        hp: hp!(2),
        teleport_counter: MONSTER_COUNTER_START,
        ..Monster::default()
    }
}

impl Monster {
    pub fn is_dead(&self) -> bool {
        self.hp == hp!(0)
    }

    fn is_player(&self) -> bool {
        self.kind == MonsterKind::Player
    }
}

pub type DisplayX = i16;
pub type DisplayY = i16;

impl Monster {
    pub fn display_x(&self) -> DisplayX {
        self.xy.x as DisplayX * OFFSET_MULTIPLE + self.offset_xy.x
    }

    pub fn display_y(&self) -> DisplayY {
        self.xy.y as DisplayY * OFFSET_MULTIPLE + self.offset_xy.y
    }
}

fn remove_monster(tiles: &mut Tiles, xy: TileXY) {
    tiles.0[xy_to_i(xy)].monster = None;
}

fn set_monster(tiles: &mut Tiles, monster: Monster) {
    tiles.0[xy_to_i(monster.xy)].monster = Some(monster);
}

fn replace(tiles: &mut Tiles, xy: TileXY, maker: fn(xy: TileXY) -> Tile) {
    tiles.0[xy_to_i(xy)] = maker(xy);
}

fn set_treasure(tiles: &mut Tiles, xy: TileXY, treasure: bool) {
    tiles.0[xy_to_i(xy)].treasure = treasure;
}

fn get_player(world: &World) -> Res<Monster> {
    let tile = world.tiles.get_tile(world.xy);
    if let Some(monster) = tile.monster {
        if monster.kind == MonsterKind::Player {
            Ok(monster)
        } else {
            Err(Error::ExpectedNonPlayerToBePlayer(world.xy, monster.kind))
        }
    } else {
        Err(Error::CouldNotFindPlayer(world.xy))
    }
}

fn move_player(world: &mut World, dxy: DeltaXY) -> Res<AfterTick> {
    get_player(world).map(move |player| {
        if let Some(moved) = try_move(world, player, dxy) {
            world.xy = moved.xy;

            tick(world)
        } else {
            AfterTick::NoChange
        }
    })
}

#[must_use]
enum AfterTick {
    NoChange,
    PlayerDied,
    CompletedRoom(HP),
}

#[must_use]
fn tick(world: &mut World) -> AfterTick {
    let monsters = world.get_monsters();

    for monster in monsters.iter() {
        if monster.is_player() {
            continue;
        }

        if monster.is_dead() {
            remove_monster(&mut world.tiles, monster.xy);
        } else {
            update_monster(world, *monster);
        }
    }

    world.spawn.counter = world.spawn.counter.saturating_sub(1);

    if world.spawn.counter == 0 {
        spawn_monster(&mut world.rng, &mut world.tiles);
        world.spawn.counter = world.spawn.rate;
        world.spawn.rate = world.spawn.rate.saturating_sub(1);
    }

    let t: Tile = world.tiles.get_tile(world.xy);
    if let Some(player) = t.monster {
        if player.is_dead() {
            return AfterTick::PlayerDied;
        }

        match t.kind {
            TileKind::Exit => {
                world.push_sound(SoundSpec::NewLevel);

                return AfterTick::CompletedRoom(player.hp);
            },
            TileKind::Floor => if t.treasure {
                world.score = world.score.saturating_add(1);

                set_treasure(&mut world.tiles, t.xy, false);
                world.push_sound(SoundSpec::Treasure);

                spawn_monster(&mut world.rng, &mut world.tiles);
            },
            _ => {}
        }
    }


    AfterTick::NoChange
}

fn try_move(world: &mut World, mut monster: Monster, dxy: DeltaXY) -> Option<Monster> {
    let new_tile = get_neighbor(&world.tiles, monster.xy, dxy);

    if new_tile.is_passable() {
        if let Some(mut target) = new_tile.monster {
            if monster.is_player() != target.is_player() {
                monster.attacked_this_turn = true;
                monster.offset_xy.x = (new_tile.xy.x as OffsetX - monster.xy.x as OffsetX) * OFFSET_MULTIPLE / 2;
                monster.offset_xy.y = (new_tile.xy.y as OffsetX - monster.xy.y as OffsetX) * OFFSET_MULTIPLE / 2;

                set_monster(&mut world.tiles, monster);

                target.stunned = true;
                target.hp = target.hp.saturating_sub(hp!(1));
                
                set_monster(&mut world.tiles, target);

                world.shake.amount = 5;

                if target.is_player() {
                    world.push_sound(SoundSpec::PlayerWasHit);
                } else {
                    world.push_sound(SoundSpec::NonPlayerWasHit);
                }
            };

            Some(monster)
        } else {
            Some(r#move(world, monster, new_tile.xy))
        }
    } else {
        None
    }
}

fn r#move(world: &mut World, monster: Monster, xy: TileXY) -> Monster {
    remove_monster(&mut world.tiles, monster.xy);

    let mut moved = monster;
    moved.offset_xy.x = (moved.xy.x as OffsetX - xy.x as OffsetX) * OFFSET_MULTIPLE;
    moved.offset_xy.y = (moved.xy.y as OffsetX - xy.y as OffsetX) * OFFSET_MULTIPLE;
    moved.xy = xy;

    set_monster(&mut world.tiles, moved);

    moved
}

fn update_monster(world: &mut World, mut monster: Monster) {
    monster.teleport_counter = monster.teleport_counter.saturating_sub(1);

    if monster.stunned || monster.teleport_counter > 0 {
        monster.stunned = false;

        set_monster(&mut world.tiles, monster);

        return;
    }

    match monster.kind {
        MonsterKind::Tank => {
            monster = do_stuff(world, monster).unwrap_or(monster);

            monster.stunned = true;
            set_monster(&mut world.tiles, monster);
        }
        MonsterKind::Snake => {
            monster.attacked_this_turn = false;

            set_monster(&mut world.tiles, monster);

            if let Some(monster) = do_stuff(world, monster) {
                if !monster.attacked_this_turn {
                    do_stuff(world, monster);
                }
            }
        },
        MonsterKind::Eater => {
            let neighbors = get_adjacent_neighbors(&mut world.rng, &world.tiles, monster.xy);
            let mut filtered = neighbors.iter()
                            .filter(|t| !t.is_passable() && in_bounds(t.xy));
    
            if let Some(neighbor) = filtered.next() {
                replace(&mut world.tiles, neighbor.xy, make_floor);
                
                monster.hp = monster.hp.saturating_add(hp!(0.5));
                set_monster(&mut world.tiles, monster);
            } else {
                do_stuff(world, monster);
            }
        },
        MonsterKind::Jester => {
            let neighbors = get_adjacent_neighbors(&mut world.rng, &world.tiles, monster.xy);
                
            let mut filtered = neighbors.iter()
                .filter(|t| t.is_passable());

            if let Some(new_tile) = filtered.next() {
                try_move(
                    world,
                    monster,
                    dxy!(
                        new_tile.xy.x as DeltaX - monster.xy.x as DeltaX,
                        new_tile.xy.y as DeltaY - monster.xy.y as DeltaY
                    )
                );
            }
        },
        _ => {
            do_stuff(world, monster);
        }
    }
}

fn do_stuff(world: &mut World, monster: Monster) -> Option<Monster> {
    let neighbors = get_adjacent_neighbors(
        &mut world.rng,
        &world.tiles,
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
            Some(t) => dist(t.xy, world.xy),
            None => TileCount::MAX,
        }
    ) {
        try_move(
            world,
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
    pub monster: Option<Monster>,
    pub treasure: bool,
}

impl Tile {
    fn is_passable(&self) -> bool {
        matches!(self.kind, TileKind::Exit | TileKind::Floor)
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

fn make_exit(xy: TileXY) -> Tile {
    Tile {
        xy,
        kind: TileKind::Exit,
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
            } else {
                tiles[i] = make_floor(xy);

                passable_tiles += 1;
            }
        }
    }

    (Tiles(tiles), passable_tiles)
}

fn generate_monsters(rng: &mut Xs, tiles: &mut Tiles, level: Level) {
    for _ in 0..level + 1 {
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
pub enum SpellPage {
    _1,
    _2,
    _3,
    _4,
    _5,
    _6,
    _7,
    _8,
    _9,
}

/// Must be the same as the number of SpellPage variants.
pub const MAX_NUM_SPELLS: SpellCount = 9;

macro_rules! def_spell_names {
    ($($variants: ident),*) => {
        #[derive(Copy, Clone, Debug)]
        pub enum SpellName {
            $($variants),*
        }
        
        const SPELL_NAME_COUNT: usize = 1;

        const ALL_SPELL_NAMES: [SpellName; SPELL_NAME_COUNT] = [
            $(SpellName::$variants),*
        ];

        const ALL_SPELL_NAME_STRS: [&str; SPELL_NAME_COUNT] = [
            $(stringify!($variants)),*
        ];

        impl core::fmt::Display for SpellName {
            fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
                write!(f, "{}", ALL_SPELL_NAME_STRS[*self as usize])
            }
        }
    }
}

def_spell_names!{
    WOOP
}

type SpellCount = u8;

pub type SpellBook = [Option<SpellName>; MAX_NUM_SPELLS as usize];

type Spell = fn (world: &mut World) -> Res<()>;

fn cast_spell(world: &mut World, page: SpellPage) -> Res<AfterTick> {
    let mut after_tick = AfterTick::NoChange;
    let mut after_spell = Ok(());

    if let Some(spell_name) = world.spells[page as usize].take() {
        use SpellName::*;
        let spell = match spell_name {
            WOOP => woop,
        };

        after_spell = spell(world);

        world.push_sound(SoundSpec::Spell);

        after_tick = tick(world);
    }

    after_spell.map(|spell| {
        after_tick
    })
}

fn woop(world: &mut World) -> Res<()> {
    get_player(world).map(|player| {
        if let Ok(new_tile) = random_passable_tile(&mut world.rng, &world.tiles) {
            world.xy = r#move(world, player, new_tile.xy).xy;
        } else {
            // If the player tries to teleport when there is no free space
            // I'm not sure what else they would expect to happen. But I
            // know that they wouldn't want the game to freeze with an error.
            ()
        }
    })
}

#[derive(Copy, Clone)]
pub enum Input {
    Empty,
    Up,
    Down,
    Left,
    Right,
    Cast(SpellPage),
}

fn advance_offsets(world: &mut World) {
    // Monster offsets
    for t in world.tiles.0.iter_mut() {
        if let Some(monster) = t.monster.as_mut() {
            monster.offset_xy.x -= monster.offset_xy.x.signum();
            monster.offset_xy.y -= monster.offset_xy.y.signum();
        }
    }

    // Screenshake offsets
    let shake = &mut world.shake;
    if shake.amount > 0 {
        shake.amount -= 1;

        // An extremely approximate version of picking a random angle, taking
        // cos/sin of the angle, multiplying that by shake.amount.
        
        // We ask for 2 more random bits to determine the quadrant.
        let max_offset = (shake.amount as OffsetX) * OFFSET_MULTIPLE;
        let shake_spec = xs_u32(&mut shake.rng, 0, (max_offset as u32 + 1) << 2);
        
        // Here we pull those bits out.
        let quadrant = shake_spec & ((1 << 2) - 1);
        // Here we slide those bits off to get random number from 0 to max_offset.
        shake.xy.x = (shake_spec >> 2) as OffsetX;
        // On a unit square diamond, (our extreme appoximation to a unit circle)
        // |x| + |y| == 1
        // We skip the absolute value part by staying in the positive quadrant for now.
        shake.xy.y = max_offset - shake.xy.x;
    
        // check each quadrant bit in turn to decide whether to flip across each axis.
        if quadrant & 1 == 0 {
            shake.xy.x *= -1;
        }
        if quadrant & 2 == 0 {
            shake.xy.y *= -1;
        }
    }
}

pub enum UpdateEvent {
    NothingNoteworthy,
    PlayerDied(Score),
    CompletedRun(Score),
}

pub fn update(state: &mut State, input: Input) -> UpdateEvent {
    use State::*;
    use Input::*;

    let mut event = UpdateEvent::NothingNoteworthy;

    enum SwitchVariant {
        NoChange,
        ToDead,  // From Running
        ToTitle, // From Dead
    }

    let mut switch_variant = SwitchVariant::NoChange;

    match *state {
        TitleFirst(seed) => {
            if !matches!(input, Input::Empty) {
                *state = State::from_seed(seed);
            }
        },
        TitleReturn(ref mut world) => {
            if !matches!(input, Input::Empty) {
                *state = State::from_seed(new_seed(&mut world.rng));
            }
        },
        Running(ref mut world) => {
            world.clear_sounds();
            advance_offsets(world);

            let after_tick_res = match input {
                Empty => {
                    Ok(AfterTick::NoChange)
                },
                Up => {
                    move_player(world, dxy!(0, -1))
                },
                Down => {
                    move_player(world, dxy!(0, 1))
                },
                Left => {
                    move_player(world, dxy!(-1, 0))
                },
                Right => {
                    move_player(world, dxy!(1, 0))
                },
                Cast(page) => {
                    cast_spell(world, page)
                },
            };

            match after_tick_res {
                Ok(AfterTick::NoChange) => {
                    return event;
                },
                Ok(AfterTick::CompletedRoom(player_hp)) => {
                    if world.level == NUM_LEVELS {
                        event = UpdateEvent::CompletedRun(world.score);
                        switch_variant = SwitchVariant::ToTitle;
                    } else {
                        match World::from_seed(
                            new_seed(&mut world.rng),
                            world.level.saturating_add(1),
                            Some(player_hp.saturating_add(hp!(1))),
                            Some(world.score),
                            Some(world.num_spells),
                            world.sound_specs,
                        ) {
                            Ok(w) => { 
                                *world = w;
                            },
                            Err(e) => {
                                *state = Error(e);
                            }
                        }
                    }
                },
                Ok(AfterTick::PlayerDied) => {
                    event = UpdateEvent::PlayerDied(world.score);
                    switch_variant = SwitchVariant::ToDead;
                },
                Err(e) => {
                    *state = Error(e);
                }
            }
        },
        Dead(ref mut world) => {
            world.clear_sounds();
            advance_offsets(world);

            if !matches!(input, Input::Empty) {
                switch_variant = SwitchVariant::ToTitle;
            }
        },
        Error(_) => {},
    }

    match switch_variant {
        SwitchVariant::NoChange => {}
        SwitchVariant::ToDead => {
            let dummy_value = TitleFirst(<_>::default());
            let running = core::mem::replace(state, dummy_value);
            *state = match running {
                Running(world) => {
                    Dead(world)
                }
                _ => {
                    // This case should not happen but I guess this is better than 
                    // `unsafe`?
                    Error(crate::Error::ZombiePlayer)
                }
            };
        }
        SwitchVariant::ToTitle => {
            let dummy_value = TitleFirst(<_>::default());
            let previous = core::mem::replace(state, dummy_value);
            *state = match previous {
                Running(world) | Dead(world) => {
                    TitleReturn(world)
                }
                _ => {
                    // This case should not happen but I guess this is better than 
                    // `unsafe`?
                    Error(crate::Error::AlreadyAtTitle)
                }
            };
        }    
    }

    event
}