#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/../lib"
require 'logtrend'
require 'fileutils'

FileUtils.touch('test.log')
Dir.mkdir('/tmp/rrd') if !File.exists?('/tmp/rrd')
Dir.mkdir('/tmp/graphs') if !File.exists?('/tmp/graphs')

LogTrend.start('test.log', "/tmp/rrd", "/tmp/graphs") do |l|
  l.trends = {
    :total => /.*/,
    :fbod => /fogbugz.com/,
    :kod => /kilnhg.com/
  }
  
  l.graphs = {
    "requests_per_minute" => {
      :fbod => '#0066cc',
      :kod => '#993333'
    }
  }
end
