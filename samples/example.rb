#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/../lib"
require 'logtrend'
require 'fileutils'

FileUtils.touch('test.log')

LogTrend.start('test.log') do |l|
  l.trends = {
    :total => /.*/,
    :fbod => /fogbugz.com/,
    :kod => /kilnhg.com/
  }
  
  l.graphs = {
    "requests_per_minute" => {
      :total => '#0066cc',
      :kod => '#993333'
    }
  }
end
