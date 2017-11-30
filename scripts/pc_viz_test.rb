#! /usr/bin/env ruby

require 'rock/bundle'
require 'vizkit'

include Orocos

Bundles.initialize
Bundles.transformer.load_conf(
    Bundles.find_file('config', 'transforms_scripts.rb'))

Orocos.run(
    ####### Tasks #######
    'camera_bb2::Task' => 'camera_bb2',
    'camera_bb3::Task' => 'camera_bb3',
    'stereo::Task' => 'stereo',
    'viso2::StereoOdometer' => 'viso2',
    'cartographer::Task' => 'cartographer',
    ####### Debug #######
    # :output => '%m-%p.log',
    # :gdb => ['cartographer'],
    # :valgrind => ['stereo'],
    :valgrind_options => ['--track-origins=yes']) \
do
    ####### Replay #######
    bag = Orocos::Log::Replay.open(
        '~/rock_bags/bb2.log',
        '~/rock_bags/bb3.log',
        '~/rock_bags/waypoint_navigation.log',
        '~/rock_bags/imu.log',
    )
    bag.use_sample_time = true

    ####### Configure #######
    camera_bb2 = TaskContext.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['default'], :override => true)
    camera_bb2.configure

    camera_bb3 = TaskContext.get 'camera_bb3'
    Orocos.conf.apply(camera_bb3, ['default'], :override => true)
    camera_bb3.configure

    stereo = TaskContext.get 'stereo'
    Orocos.conf.apply(stereo, ['hdpr_bb3_left_right'], :override => true)
    stereo.configure

    viso2 = TaskContext.get 'viso2'
    Orocos.conf.apply(viso2, ['bumblebee'], :override => true)
    Bundles.transformer.setup(viso2)
    viso2.configure

    cartographer = TaskContext.get 'cartographer'
    Bundles.transformer.setup(cartographer)
    cartographer.configure

    ####### Connect #######
    bag.camera_firewire_bb2.frame.connect_to        camera_bb2.frame_in
    bag.camera_firewire_bb3.frame.connect_to        camera_bb3.frame_in
    camera_bb3.left_frame.connect_to                stereo.left_frame
    camera_bb3.right_frame.connect_to               stereo.right_frame
    camera_bb2.left_frame.connect_to                viso2.left_frame
    camera_bb2.right_frame.connect_to               viso2.right_frame

    stereo.distance_frame.connect_to                cartographer.distance_image
    # viso2.pose_samples_out.connect_to               cartographer.pose_imu
    # bag.gps_heading.pose_samples_out.connect_to     cartographer.pose_imu
    bag.imu_stim300.orientation_samples_out.connect_to \
                                                    cartographer.pose_imu

    ####### Start #######
    # camera_bb2.start
    camera_bb3.start
    stereo.start
    # viso2.start
    cartographer.start

    ####### Vizkit #######
    control = Vizkit.control bag
    control.speed = 1
    control.seek_to 2600
    control.bplay_clicked

    # Vizkit.display viso2.pose_samples_out,
        # :widget => Vizkit.default_loader.RigidBodyStateVisualization
    # Vizkit.display viso2.pose_samples_out,
        # :widget => Vizkit.default_loader.TrajectoryVisualization
    # Vizkit.display bag.gps_heading.pose_samples_out,
        # :widget => Vizkit.default_loader.TrajectoryVisualization

    # Vizkit.display camera_bb2.left_frame
    Vizkit.display camera_bb3.left_frame

    # Vizkit.display stereo.point_cloud
    # Vizkit.display viso2.point_cloud_samples_out
    # Vizkit.display cartographer.heightMap_frame
    # Vizkit.display cartographer.heightMapInterp_frame
    # Vizkit.display cartographer.pointcloud_in
    Vizkit.display cartographer.pointcloud_filter

    Vizkit.exec
end

