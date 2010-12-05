# The story: you have all sorts of logs, 
# and you want to get an idea how often certain 
# events occur each minute

# Perhaps you just want to know how many HTTP transactions occurred.
# Maybe you are worried about unauthorized access attempts.
# How about how many customers are flogging your api endpoint?

# You need to see the outliers.  Grepping through log files 
# in the midst of a crisis is very hard to do and quite unproductive.
# This is especially true in environments with lots of transactions. 

# With this tool, you can begin categorizing events 
# in your logs and trend them.  Then, when crisis hits, you can
# take a look at the graphs to see if anything suspicious has occurred 
# over the last few minutes.

$:.unshift "#{File.dirname(__FILE__)}/../lib"
require 'logtrend'
require 'fileutils'

FileUtils.touch('test.log')

# Invoke this to begin trending your data...
LogTrend::Base.run("test.log") do |lt|
  
  # Set new locations for our graphs and rrds.  defaults to '.'
  lt.rrd_dir = '/tmp/rrd'
  lt.graphs_dir = '/tmp/graphs'
  
  # Add some things to trend.  An RRD is built for each one of these items.
  # Each time we read a line from the log file, we pass it to the block.
  # If your block returns true, we count that as a hit.
  # Every minute, the RRD is updated with the hits for the previous period.
  lt.add_trend(:total) {|line| line.match /.*/}
  lt.add_trend(:fbod) {|line| line.match /fogbugz.com/}
  lt.add_trend(:kod) {|line| line.match /kilnhg.com/}
  lt.add_trend(:long) do |line|
    # Let us pretend that request time is in seconds
    # and is the last item on the log line
    request_time = line.split.last.to_i
    request_time > 10
  end
  
  # Build a graph displaying some of the items we are trending
  # Label it as :requests_per_minute
  lt.add_graph(:requests_per_minute) do |g|
    g.add_point :area, :total, "#333333"
    g.add_point :line, :fbod, "#0066cc"
    g.add_point :line, :kod, "#993333"
  end

  # Build a second graph for our long running queries
  lt.add_graph(:long_requests) do |g|
    g.add_point :area, :long, '#000000'
  end
  
end