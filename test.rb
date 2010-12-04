#!/usr/bin/env ruby

require 'logtrend'

LogTrend.new.start('test.log') do |l|
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