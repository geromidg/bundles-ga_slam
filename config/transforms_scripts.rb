Quaternion = Eigen::Quaternion
Vector = Eigen::Vector3
PI = Math::PI

static_transform \
    Quaternion.from_euler(Vector.new(
        -PI/2,
        0.023,
        -PI/2 - 0.574),
        2, 1, 0),
    Vector.new(
        0.527,
        0.073,
        0.858),
    "left_camera_bb2" => "body"

static_transform \
    Quaternion.from_euler(Vector.new(
        -PI/2 + 0.005,
        0.321,
        -PI/2 - 0.066),
        2, 1, 0),
    Vector.new(
        0.426,
        0.129,
        1.491),
    "left_camera_bb3" => "body"

static_transform \
    Quaternion.from_euler(Vector.new(
        -PI/2,
        0.0,
        -PI/2),
        2, 1, 0),
    Vector.new(
        0.010,
        0.250,
        0.055),
    "left_camera_pancam" => "ptu"

static_transform \
    Quaternion.from_euler(Vector.new(
        -PI/2,
        -0.050 + 0.392,
        -PI/2),
        2, 1, 0),
    Vector.new(
        0.138,
        -0.005,
        1.860),
    "ptu" => "body"

static_transform Quaternion.Identity(), Vector.Zero(),
    "left_camera_viso2" => "left_camera_bb2"

static_transform Quaternion.Identity(), Vector.Zero(),
    # "slamCamera" => "left_camera_bb2"
    "slamCamera" => "left_camera_bb3"
    # "slamCamera" => "left_camera_pancam"

