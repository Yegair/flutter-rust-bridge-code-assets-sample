use flutter_rust_bridge::frb;

#[frb(init)]
pub fn init() {}

#[frb(sync)]
pub fn add(left: i32, right: i32) -> i32 {
    sample_rust_lib::add(left, right)
}
