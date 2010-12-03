#!/usr/bin/env ruby

require 'logtrend'

l = LogTrend.new
l.trends = {
  :total => /.*/,
  :fbod => /fogbugz.com/,
  :kod => /kilnhg.com/
}

l.graphs = {
  "requests per minute" => {
    :fbod => '#0066cc',
    :kod => '#993333'
  }
}

l.start('test.log')