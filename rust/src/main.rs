#![deny(unused)]

use state::{State, Input};

const AQUA: macroquad::Color = macroquad::Color([0, 0xff, 0xff, 0xff]);
const INDIGO: macroquad::Color = macroquad::Color([0x4b, 0, 0x82, 0xff]);
const OVERLAY: macroquad::Color = macroquad::Color([0, 0, 0, 0xcc]);
const VIOLET: macroquad::Color = macroquad::Color([0xee, 0x82, 0xee, 0xff]);

const SPRITESHEET_BYTES: &[u8] = include_bytes!("../assets/spritesheet.png");

#[macroquad::main("AWESOME BROUGHLIKE")]
async fn main() {
    let spritesheet = {
        let ctx = &mut miniquad::graphics::Context::new();
        let texture = macroquad::Texture2D::from_file_with_format(
            ctx,
            SPRITESHEET_BYTES,
            None,
        );

        texture.set_filter(ctx, macroquad::FilterMode::Nearest);

        texture
    };

    let seed: u128 = {
        use std::time::SystemTime;

        let duration = match 
            SystemTime::now()
                .duration_since(SystemTime::UNIX_EPOCH)
        {
            Ok(d) => d,
            Err(err) => err.duration(),
        };

        duration.as_nanos()
    };

    println!("{}", seed);

    let state: &mut State = &mut State::TitleFirst(seed.to_le_bytes());

    type Size = f32;

    const UI_FONT_SIZE: Size = 36.;

    struct Sizes {
        play_area_x: Size,
        play_area_y: Size,
        play_area_w: Size,
        play_area_h: Size,
        tile: Size,
    }

    fn fresh_sizes() -> Sizes {
        let w = macroquad::screen_width();
        let h = macroquad::screen_height();

        let w_in_tiles = (state::NUM_TILES + state::UI_WIDTH) as Size;
        let h_in_tiles = state::NUM_TILES as Size;

        let tile = Size::min(
            w / w_in_tiles,
            h / h_in_tiles,
        );

        let play_area_w = tile * w_in_tiles;
        let play_area_h = tile * h_in_tiles;
        let play_area_x = (w - play_area_w) / 2.;
        let play_area_y = (h - play_area_h) / 2.;

        Sizes {
            play_area_x,
            play_area_y,
            play_area_w,
            play_area_h,
            tile,
        }
    }

    let mut scores = Scores::new();
    match scores.save_path {
        Ok(ref p) => println!("Will save to {}", p.to_string_lossy()),
        Err(ref e) => eprintln!("{}", e),
    };

    let score_header = &right_pad(&["RUN","SCORE","TOTAL"]);
    let score_header_first_column = &right_pad(&["RUN"]);
    let score_header_first_two_columns = &right_pad(&["RUN","SCORE"]);
    // This is to account for the fact that the last column has 5 extra spaces 
    // after it, so the centering seems off, bacuase it's based on the full text 
    // width.
    const SCORE_NUDGE_IN_EMS: Size = 5.;

    loop {
        let sizes = fresh_sizes();

        macroquad::clear_background(INDIGO);
        let mut input = Input::Empty;
        macro_rules! take_input {
            ($input: ident) => {
                take_input!($input, $input)
            };
            ($input: ident, $key_code: ident) => {
                if macroquad::is_key_pressed(macroquad::KeyCode::$key_code) {
                    input = Input::$input;
                }
            }
        }
        take_input!(Right);
        take_input!(Right, D);
        take_input!(Left);
        take_input!(Left, A);
        take_input!(Down);
        take_input!(Down, S);
        take_input!(Up);
        take_input!(Up, W);

        let event = state::update(state, input);

        scores.add(event);

        // the -1 and +2 business makes the border lie just outside the actual
        // play area
        macroquad::draw_rectangle_lines(
            sizes.play_area_x - 1.,
            sizes.play_area_y - 1.,
            sizes.play_area_w + 2.,
            sizes.play_area_h + 2.,
            1.,
            macroquad::WHITE
        );

        let draw_sprite_float = |sprite: state::SpriteIndex, (x, y): (Size, Size)| {
            macroquad::draw_texture_ex(
                spritesheet,
                sizes.play_area_x + x,
                sizes.play_area_y + y,
                macroquad::WHITE,
                macroquad::DrawTextureParams {
                    dest_size: Some(macroquad::Vec2::new(sizes.tile, sizes.tile)),
                    source: Some(macroquad::Rect {
                        x: 16. * sprite as f32 + sprite as f32,
                        y: 0.,
                        w: 16.,
                        h: 16.,
                    }),
                    rotation: 0.,
                }
            );
        };

        let draw_sprite = |sprite: state::SpriteIndex, xy: state::TileXY| {
            draw_sprite_float(
                sprite,
                (
                    sizes.tile * (xy.x as Size),
                    sizes.tile * (xy.y as Size)
                )
            )
        };

        enum TextMode {
            TitleTop,
            TitleBottom,
            UI,
            ScoreHeader,
            ScoreCol1,
            ScoreCol2,
            ScoreCol3,
        }

        struct TextSpec<'text> {
            pub text: &'text str,
            pub mode: TextMode,
            pub y: Size,
            pub colour: macroquad::Color,
        }

        let draw_text = |TextSpec { text, mode, y, colour, }: TextSpec| {
            let em = macroquad::measure_text("m", UI_FONT_SIZE).0;

            let (size, mut x)  = match mode {
                TextMode::TitleTop => {
                    let size = 40.0;
                    (
                        size,
                        (sizes.play_area_w - macroquad::measure_text(text, size).0)/2.
                    )
                },
                TextMode::TitleBottom => {
                    let size = 70.0;
                    (
                        size,
                        (sizes.play_area_w - macroquad::measure_text(text, size).0)/2.
                    )
                },
                TextMode::ScoreHeader => {
                    let size = UI_FONT_SIZE;
                    (
                        size,
                        (
                            sizes.play_area_w 
                            - macroquad::measure_text(text, size).0
                            + SCORE_NUDGE_IN_EMS * em
                        )/2.
                    )
                },
                TextMode::ScoreCol1 => {
                    let size = UI_FONT_SIZE;
                    (
                        size,
                        (
                            sizes.play_area_w
                            - macroquad::measure_text(score_header, size).0
                            + SCORE_NUDGE_IN_EMS * em
                        )/2.
                    )
                },
                TextMode::ScoreCol2 => {
                    let size = UI_FONT_SIZE;
                    (
                        size,
                        (
                            sizes.play_area_w
                            - macroquad::measure_text(score_header, size).0
                            + SCORE_NUDGE_IN_EMS * em
                        )/2.
                        + macroquad::measure_text(score_header_first_column, size).0
                    )
                },
                TextMode::ScoreCol3 => {
                    let size = UI_FONT_SIZE;
                    (
                        size,
                        (
                            sizes.play_area_w
                            - macroquad::measure_text(score_header, size).0
                            + SCORE_NUDGE_IN_EMS * em
                        )/2.
                        + macroquad::measure_text(score_header_first_two_columns, size).0
                    )
                },
                TextMode::UI => {
                    (
                        UI_FONT_SIZE,
                        (state::NUM_TILES as Size) * sizes.tile + em,
                    )
                },
            };
            x += sizes.play_area_x;

            macroquad::draw_text(
                text,
                x,
                y,
                size,
                colour,
            );
        };

        let mut draw_title = || {
            macroquad::draw_rectangle(
                sizes.play_area_x,
                sizes.play_area_y,
                sizes.play_area_w,
                sizes.play_area_h,
                OVERLAY
            );

            draw_text(TextSpec {
                text: "Rust-some",
                mode: TextMode::TitleTop,
                y: sizes.play_area_y + (sizes.play_area_h * 3./8.),
                colour: macroquad::WHITE,
            });

            draw_text(TextSpec {
                text: "Broughlike",
                mode: TextMode::TitleBottom,
                y: sizes.play_area_y + (sizes.play_area_h * 13./32.),
                colour: macroquad::WHITE,
            });

            //
            // Draw the scores
            //

            let mut rows: Vec<ScoreRow> = scores.get();
            if let Some(newest_row) = rows.pop() {
                draw_text(TextSpec {
                    text: score_header,
                    mode: TextMode::ScoreHeader,
                    y: sizes.play_area_y + (sizes.play_area_h * 0.5),
                    colour: macroquad::WHITE,
                });

                rows.sort_by_key(|a| a.total_score);
        
                rows.insert(0, newest_row);
        
                for i in 0u8..(10.min(rows.len())) as u8 {
                    let row: &ScoreRow = &rows[i as usize];

                    let row_h = sizes.play_area_h * 1./24.;

                    let spec = TextSpec {
                        text: &format!("{}", row.total_score),
                        mode: TextMode::ScoreCol1,
                        y: sizes.play_area_y + (sizes.play_area_h * 0.5)
                            + row_h + i as Size * row_h,
                        colour: if i == 0 { AQUA } else { VIOLET },
                    }; 

                    draw_text(TextSpec {
                        text: &format!("{}", row.run),
                        mode: TextMode::ScoreCol3,
                        ..spec
                    });
                    draw_text(TextSpec {
                        text: &format!("{}", row.score),
                        mode: TextMode::ScoreCol2,
                        ..spec
                    });
                    draw_text(spec);
                }
            }
        };

        let draw_world = |world: &state::World| {
            for t in world.tiles.iter() {
                draw_sprite(match t.kind {
                    state::TileKind::Floor => 2,
                    state::TileKind::Wall => 3,
                    state::TileKind::Exit => 11,
                }, t.xy);

                if t.treasure {
                    draw_sprite(12, t.xy);
                }
    
                if let Some(monster) = t.monster {
                    if monster.teleport_counter > 0 {
                        draw_sprite(10, monster.xy);
                        continue;
                    }

                    let monster_sprite = match monster.kind {
                        state::MonsterKind::Player => if monster.is_dead() {
                            1
                        } else {
                            0
                        },
                        state::MonsterKind::Bird => 4,
                        state::MonsterKind::Snake => 5,
                        state::MonsterKind::Tank => 6,
                        state::MonsterKind::Eater => 7,
                        state::MonsterKind::Jester => 8,
                    };
    
                    draw_sprite(monster_sprite, monster.xy);
    
                    // drawing the HP {
                    let pips = state::hp!(get pips monster.hp);
                    for i in 0..pips {
                        draw_sprite_float(
                            9,
                            (
                                sizes.tile * (
                                    monster.xy.x as Size 
                                    + (i % 3) as Size * (5./16.)
                                ),
                                sizes.tile * (
                                    monster.xy.y as Size 
                                    - (i / 3) as Size * (5./16.)
                                )
                            )
                        );
                    }
                    // }
                }
            }

            draw_text(TextSpec {
                text: &format!("Level: {}", world.level),
                mode: TextMode::UI,
                y: sizes.play_area_y,
                colour: VIOLET,
            });

            draw_text(TextSpec {
                text: &format!("Score: {}", world.score),
                mode: TextMode::UI,
                y: sizes.play_area_y + UI_FONT_SIZE,
                colour: VIOLET,
            });
        };

        match state {
            state::State::TitleFirst(_) => {
                draw_title();
            },
            state::State::TitleReturn(ref world) => {
                draw_world(world);
                draw_title();
            },
            state::State::Running(ref world)
            | state::State::Dead(ref world) => {
                draw_world(world);
            },
            state::State::Error(e) => {
                macroquad::draw_text(
                    &format!(
                        "Error: {:#?}", e
                    ),
                    sizes.play_area_x,
                    sizes.play_area_y,
                    40.0,
                    macroquad::RED,
                );
            }
        }

        macroquad::next_frame().await
    }
}

// 64k runs ought to be enough for anybody.
type Runs = u16;

#[derive(Clone)]
struct ScoreRow {
    score: state::Score,
    total_score: state::Score,
    run: Runs,
    active: bool,
}

struct Scores {
    save_path: std::io::Result<std::path::PathBuf>,
    cache: Option<Vec<ScoreRow>>,
}

impl Scores {
    fn new() -> Self {
        let save_path = std::env::current_exe()
            .map(|p| 
                p
                    .parent()
                    .map(std::path::PathBuf::from)
                    .unwrap_or(p)
                    .join("broughlike.sav")
            );

        Self {
            save_path,
            cache: None,
        }
    }

    fn get(&mut self) -> Vec<ScoreRow> {
        if let Some(ref scores) = self.cache {
            scores.clone()
        } else {
            let mut output = Vec::with_capacity(16);

            if let Ok(ref path) = self.save_path {
                if let Ok(s) = std::fs::read_to_string(path) {
                    for line in s.lines() {
                        let mut columns = line.split('\t');

                        let mut row = ScoreRow {
                            score: 0,
                            total_score: 0,
                            run: 0,
                            active: false,
                        };

                        macro_rules! parse_or_continue {
                            ($field: ident as $type: ty) => {
                                parse_or_continue!($field as $type, { $field });
                            };
                            ($field: ident as $type: ty, $transform: block) => {
                                if let Some($field) = columns.next()
                                    .and_then(|s| s.trim().parse::<$type>().ok()) {
                                    row.$field = $transform;
                                } else {
                                    continue;
                                }
                            }
                        }

                        parse_or_continue!(score as state::Score);
                        parse_or_continue!(total_score as state::Score);
                        parse_or_continue!(run as Runs);
                        parse_or_continue!(active as u8, { active > 0 });

                        output.push(row);
                    }
                }
            }

            self.cache = Some(output.clone());

            output
        }
    }
    
    fn add(&mut self, event: state::UpdateEvent) {
        let (score, won) = match event {
            state::UpdateEvent::PlayerDied(s) => (s, false),
            state::UpdateEvent::CompletedRun(s) => (s, true),
            state::UpdateEvent::NothingNoteworthy => return,
        };
    
        let mut scores = self.get();
        let mut score_row = ScoreRow {score, run: 1, total_score: score, active: won};
    
        if let Some(last_score) = scores.pop() {
            if last_score.active {
                score_row.run = last_score.run + 1;
                score_row.total_score += last_score.total_score;
            } else {
                scores.push(last_score);
            }
        }
    
        scores.push(score_row);
    
        if let Ok(ref path) = self.save_path {
            let mut save_data = String::with_capacity(1024);
            
            for row in scores {
                save_data += &format!(
                    "{}\t{}\t{}\t{}\n",
                    row.score,
                    row.total_score,
                    row.run,
                    if row.active { 1 } else { 0 },
                );
            }

            let result: std::io::Result<_> = std::fs::write(path, save_data);
    
            match result {
                Ok(_) => {
                    self.cache = None;
                }
                Err(e) => {
                    // Presumably, the player thinks getting to play with no high
                    // scores saved is better than not being able to play.
                    eprintln!("{}", e);
                }
            }
        }
    }
}

fn right_pad(strs: &[&str]) -> String {
    let mut result = String::with_capacity(10 * strs.len());

    for text in strs {
        result += text;
        for _ in text.len()..10 {
            result += " ";
        }
    }

    result
}