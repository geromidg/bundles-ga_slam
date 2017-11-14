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
           # :gdb => ['stereo'],
           # :valgrind => ['stereo'],
           :valgrind_options => ['--track-origins=yes'],
           :wait => '1',
           :output => '%m-%p.log' \
do
    bag = Orocos::Log::Replay.open(
        "~/rock_bags/bb2.log",
        "~/rock_bags/gps.log")
    bag.use_sample_time = true

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

    bag.camera_firewire_bb2.frame.connect_to    camera_bb2.frame_in
    camera_bb2.left_frame.connect_to            stereo.left_frame
    camera_bb2.right_frame.connect_to           stereo.right_frame
    camera_bb2.left_frame.connect_to            viso2.left_frame
    camera_bb2.right_frame.connect_to           viso2.right_frame

    camera_bb2.start
    stereo.start
    viso2.start

    ####### Vizkit #######

    control = Vizkit.control bag
    control.speed = 1
    control.seek_to 1000
    control.bplay_clicked

    Vizkit.display camera_bb2.left_frame
    Vizkit.display stereo.point_cloud
    Vizkit.display viso2.point_cloud_samples_out
    Vizkit.display viso2.pose_samples_out,
        :widget => Vizkit.default_loader.RigidBodyStateVisualization
    Vizkit.display viso2.pose_samples_out,
        :widget => Vizkit.default_loader.TrajectoryVisualization
    # Vizkit.display bag.gps_heading.pose_samples_out,
        # :widget => Vizkit.default_loader.RigidBodyStateVisualization

    Vizkit.exec
end

