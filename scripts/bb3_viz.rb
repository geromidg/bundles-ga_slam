#! /usr/bin/env ruby

require 'rock/bundle'
require 'vizkit'

include Orocos

Bundles.initialize

Orocos.run(
    ####### Tasks #######
    'camera_bb3::Task' => 'camera_bb3',
    ####### Debug #######
    # :output => '%m-%p.log',
    # :gdb => ['cartographer'],
    # :valgrind => ['stereo'],
    :valgrind_options => ['--track-origins=yes']) \
do
    ####### Replay #######
    bag = Orocos::Log::Replay.open(
        '~/rock_bags/bb3.log',
    )
    bag.use_sample_time = true

    ####### Configure #######
    camera_bb3 = TaskContext.get 'camera_bb3'
    Orocos.conf.apply(camera_bb3, ['default'], :override => true)
    camera_bb3.configure

    ####### Connect #######
    bag.camera_firewire_bb3.frame.connect_to        camera_bb3.frame_in

    ####### Start #######
    camera_bb3.start

    ####### Vizkit #######
    control = Vizkit.control bag
    control.speed = 100
    control.seek_to 1400
    control.bplay_clicked

    Vizkit.display camera_bb3.left_frame

    Vizkit.exec
end

