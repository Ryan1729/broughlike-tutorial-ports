#![deny(unused)]

use state::{State, Input};

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

        state::update(state, input);

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
        }

        struct TextSpec<'text> {
            pub text: &'text str,
            pub mode: TextMode,
            pub y: Size,
            pub colour: macroquad::Color,
        }

        let draw_text = |TextSpec { text, mode, y, colour, }: TextSpec| {
            let (size, x)  = match mode {
                TextMode::TitleTop => {
                    let size = 40.0;
                    (
                        size,
                        sizes.play_area_x + (sizes.play_area_w - macroquad::measure_text(text, size).0)/2.
                    )
                },
                TextMode::TitleBottom => {
                    let size = 70.0;
                    (
                        size,
                        sizes.play_area_x + (sizes.play_area_w - macroquad::measure_text(text, size).0)/2.
                    )
                },
                TextMode::UI => {
                    let em = macroquad::measure_text("m", UI_FONT_SIZE).0;
                    (
                        UI_FONT_SIZE,
                        sizes.play_area_x + (state::NUM_TILES as Size) * sizes.tile + em,
                    )
                },
            };

            macroquad::draw_text(
                text,
                x,
                y,
                size,
                colour,
            );
        };

        let draw_title = || {
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