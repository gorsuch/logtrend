#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/../lib"
require 'logtrend'
require 'fileutils'

FileUtils.touch('test.log')
Dir.mkdir('/tmp/rrd') if !File.exists?('/tmp/rrd')
Dir.mkdir('/tmp/graphs') if !File.exists?('/tmp/graphs')

LogTrend.start("test.log") do |l|
  
  l.rrd_dir = '/tmp/rrd'
  l.graphs_dir = '/tmp/graphs'
  
  l.add_trend(:total) {|line| line.match /.*/}
  l.add_trend(:fbod) {|line| line.match /fogbugz.com/}
  l.add_trend(:kod) {|line| line.match /kilnhg.com/}
  
  l.add_graph(:requests_per_minute) do |g|
    g.add_point :area, :total, "#333333"
    g.add_point :line, :fbod, "#0066cc"
    g.add_point :line, :kod, "#993333"
  end
  
end
