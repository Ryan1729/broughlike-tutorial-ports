#[macroquad::main("AWESOME BROUGHLIKE")]
async fn main() {
    loop {
        macroquad::clear_background(macroquad::BLACK);

        macroquad::draw_rectangle(
            20.,
            20.,
            20.,
            20.,
            macroquad::WHITE
        );

        macroquad::next_frame().await
    }
}