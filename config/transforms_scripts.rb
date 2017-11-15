static_transform \
    Eigen::Quaternion.from_euler(
        Eigen::Vector3.new(-1.5666, 0.02348, -2.145), 2, 1, 0),
    Eigen::Vector3.new(0.527, 0.0738, 0.0588),
    "left_camera_viso2" => "body"

static_transform Eigen::Quaternion.from_angle_axis(
    Math::PI, Eigen::Vector3.UnitZ),
    Eigen::Vector3.new( 0.0, 0.0, 0.0 ),
    "imu" => "body"

dynamic_transform "viso2.pose_samples_out", "body" => "world_osg"
dynamic_transform "viso2.pose_samples_out", "body" => "viso_world"

