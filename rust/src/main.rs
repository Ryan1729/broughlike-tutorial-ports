#[macroquad::main("AWESOME BROUGHLIKE")]
async fn main() {
    loop {
        macroquad::clear_background(macroquad::BLACK);

        macroquad::draw_text(
            "Hello world!",
            20.0,
            20.0,
            40.0,
            macroquad::WHITE
        );

        macroquad::next_frame().await
    }
}