use state::{State, Input};

#[macroquad::main("AWESOME BROUGHLIKE")]
async fn main() {
    let state: &mut State = &mut State::default();

    loop {
        macroquad::clear_background(macroquad::BLACK);
        let mut input = Input::Empty;
        macro_rules! take_input {
            ($input: ident) => {
                take_input!($input, $input)
            };
            ($input: ident, $key_code: ident) => {
                if macroquad::is_key_down(macroquad::KeyCode::$key_code) {
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

        macroquad::draw_rectangle(
            state.xy.x as _,
            state.xy.y as _,
            20.,
            20.,
            macroquad::WHITE
        );

        macroquad::next_frame().await
    }
}