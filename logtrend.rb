require 'rubygems'
require 'eventmachine'
require 'eventmachine-tail'

class LogTrend
  attr_accessor :trends
  attr_accessor :graphs
  
  def initialize
    trends = {}
    graphs = {}
  end
  
  def start(logfile)
    
  end
end