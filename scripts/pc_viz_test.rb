#! /usr/bin/env ruby

require 'orocos'
require 'orocos/log'
require 'rock/bundle'
require 'vizkit'

include Orocos

Bundles.initialize
Bundles.transformer.load_conf(
    Bundles.find_file('config', 'transforms_scripts.rb'))

Orocos.run "camera_bb2::Task" => "camera_bb2",
           "stereo::Task" => "stereo",
           "viso2::StereoOdometer" => "viso2",
           "cartographer::Task" => "cartographer",
           # :gdb => ['cartographer'],
           # :valgrind => ['stereo'],
           :valgrind_options => ['--track-origins=yes'],
           :output => '%m-%p.log' \
do
    bag = Orocos::Log::Replay.open("~/workspace/rock/logs/slam_test/bb2.log")
    bag.use_sample_time = true
    gps = Orocos::Log::Replay.open("~/workspace/rock/logs/slam_test/gps.log")
    gps.use_sample_time = true

    camera_bb2 = TaskContext.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['default'], :override => true)
    camera_bb2.configure

    stereo = TaskContext.get 'stereo'
    Orocos.conf.apply(stereo, ['hdpr_bb2'], :override => true)
    stereo.configure

    viso2 = TaskContext.get 'viso2'
    Orocos.conf.apply(viso2, ['bumblebee'], :override => true)
    Bundles.transformer.setup(viso2)
    viso2.configure

    cartographer = TaskContext.get 'cartographer'
    Orocos.conf.apply(cartographer, ['default'], :override => true)
    Bundles.transformer.setup(cartographer)
    cartographer.configure

    bag.camera_firewire_bb2.frame.connect_to    camera_bb2.frame_in
    camera_bb2.left_frame.connect_to            stereo.left_frame
    camera_bb2.right_frame.connect_to           stereo.right_frame
    camera_bb2.left_frame.connect_to            viso2.left_frame
    camera_bb2.right_frame.connect_to           viso2.right_frame
    stereo.distance_frame.connect_to            cartographer.distance_image
    viso2.pose_samples_out.connect_to           cartographer.pose_in

    camera_bb2.start
    stereo.start
    viso2.start
    sleep 1; cartographer.start

    ####### Vizkit #######

    control_1 = Vizkit.control bag
    control_1.speed = 1
    control_1.seek_to 1000
    control_1.bplay_clicked

    control_2 = Vizkit.control gps
    control_2.speed = 1
    control_2.seek_to 3562
    control_2.bplay_clicked

    Vizkit.display camera_bb2.left_frame
    Vizkit.display stereo.point_cloud
    # Vizkit.display viso2.point_cloud_samples_out
    # Vizkit.display cartographer.traversability_map

    # Vizkit.display gps.gps_heading.pose_samples_out,
        # :widget => Vizkit.default_loader.RigidBodyStateVisualization
    Vizkit.display viso2.pose_samples_out,
        :widget => Vizkit.default_loader.RigidBodyStateVisualization

    Vizkit.exec
end

