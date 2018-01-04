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
    'stereo::Task' => ['stereo_bb2', 'stereo_bb3', 'stereo_pancam'],
    # 'viso2::StereoOdometer' => 'viso2',
    'ga_slam::Task' => 'ga_slam',
    'gps_transformer::Task' => 'gps_transformer',
    ####### Debug #######
    # :output => '%m-%p.log',
    # :gdb => ['ga_slam'],
    # :valgrind => ['ga_slam'],
    :valgrind_options => ['--track-origins=yes']) \
do
    ####### Replay Logs #######
    bag = Orocos::Log::Replay.open(
        '~/rock_bags/bb2.log',
        '~/rock_bags/bb3.log',
        '~/rock_bags/pancam.log',
        '~/rock_bags/waypoint_navigation.log',
        '~/rock_bags/imu.log',
    )
    bag.use_sample_time = true

    ####### Configure Tasks #######
    camera_bb2 = TaskContext.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['default'], :override => true)
    camera_bb2.configure

    camera_bb3 = TaskContext.get 'camera_bb3'
    Orocos.conf.apply(camera_bb3, ['default'], :override => true)
    camera_bb3.configure

    stereo_bb2 = TaskContext.get 'stereo_bb2'
    Orocos.conf.apply(stereo_bb2, ['hdpr_bb2'], :override => true)
    stereo_bb2.configure

    stereo_bb3 = TaskContext.get 'stereo_bb3'
    Orocos.conf.apply(stereo_bb3, ['hdpr_bb3_left_right'], :override => true)
    stereo_bb3.configure

    stereo_pancam = TaskContext.get 'stereo_pancam'
    Orocos.conf.apply(stereo_pancam, ['panCam'], :override => true)
    stereo_pancam.configure

    # viso2 = TaskContext.get 'viso2'
    # Orocos.conf.apply(viso2, ['bumblebee'], :override => true)
    # Bundles.transformer.setup(viso2)
    # viso2.configure

    ga_slam = TaskContext.get 'ga_slam'
    # Orocos.conf.apply(ga_slam, ['default'], :override => true)
    Orocos.conf.apply(ga_slam, ['test'], :override => true)
    Bundles.transformer.setup(ga_slam)
    ga_slam.configure

    gps_transformer = TaskContext.get 'gps_transformer'
    gps_transformer.configure

    ####### Connect Task Ports #######
    bag.camera_firewire_bb2.frame.connect_to        camera_bb2.frame_in
    bag.camera_firewire_bb3.frame.connect_to        camera_bb3.frame_in

    camera_bb2.left_frame.connect_to                stereo_bb2.left_frame
    camera_bb2.right_frame.connect_to               stereo_bb2.right_frame
    camera_bb3.left_frame.connect_to                stereo_bb3.left_frame
    camera_bb3.right_frame.connect_to               stereo_bb3.right_frame
    bag.pancam_panorama.left_frame_out.connect_to   stereo_pancam.left_frame
    bag.pancam_panorama.right_frame_out.connect_to  stereo_pancam.right_frame

    # stereo_bb2.point_cloud.connect_to               ga_slam.hazcamCloud
    # stereo_bb3.point_cloud.connect_to               ga_slam.loccamCloud
    stereo_pancam.point_cloud.connect_to            ga_slam.pancamCloud

    # camera_bb2.left_frame.connect_to                viso2.left_frame
    # camera_bb2.right_frame.connect_to               viso2.right_frame

    # viso2.pose_samples_out.connect_to               ga_slam.poseGuess
    bag.gps_heading.pose_samples_out.connect_to     gps_transformer.inputPose
    gps_transformer.outputPose.connect_to           ga_slam.poseGuess

    bag.pancam_panorama.pan_angle_out_degrees.connect_to    ga_slam.ptu_pan
    bag.pancam_panorama.tilt_angle_out_degrees.connect_to   ga_slam.ptu_tilt

    ####### Start Tasks #######
    camera_bb2.start
    camera_bb3.start
    stereo_bb2.start
    stereo_bb3.start
    stereo_pancam.start
    # viso2.start
    ga_slam.start
    gps_transformer.start

    ####### Vizkit Display #######
    # Vizkit.display viso2.pose_samples_out,
        # :widget => Vizkit.default_loader.RigidBodyStateVisualization
    # Vizkit.display viso2.pose_samples_out,
        # :widget => Vizkit.default_loader.TrajectoryVisualization
    # Vizkit.display gps_transformer.outputPose,
    #     :widget => Vizkit.default_loader.RigidBodyStateVisualization
    # Vizkit.display gps_transformer.outputPose,
    #     :widget => Vizkit.default_loader.TrajectoryVisualization
    # Vizkit.display ga_slam.estimatedPose,
        # :widget => Vizkit.default_loader.RigidBodyStateVisualization
    # Vizkit.display ga_slam.estimatedPose,
        # :widget => Vizkit.default_loader.TrajectoryVisualization

    # Vizkit.display camera_bb2.left_frame
    Vizkit.display camera_bb3.left_frame
    Vizkit.display bag.pancam_panorama.left_frame_out

    # Vizkit.display stereo_bb2.point_cloud
    # Vizkit.display stereo_bb3.point_cloud
    # Vizkit.display stereo_pancam.point_cloud
    # Vizkit.display viso2.point_cloud_samples_out
    # Vizkit.display ga_slam.processedCloud
    # Vizkit.display ga_slam.mapCloud

    # Vizkit.display ga_slam.rawElevationMap
    # Vizkit.display ga_slam.elevationMap

    ####### Vizkit Replay Control #######
    control = Vizkit.control bag
    control.speed = 1
    control.seek_to 3900
    control.bplay_clicked

    ####### ROS RViz #######
    # spawn 'roslaunch ga_slam_visualization ga_slam_visualization.launch'
    # sleep 3

    ####### Vizkit #######
    Vizkit.exec
end

