require 'rubygems'
require 'eventmachine'
require 'eventmachine-tail'
require 'rrd'

class LogTrend
  attr_accessor :trends
  attr_accessor :graphs
  
  def initialize
    trends = {}
    graphs = {}
  end
  
  def start(logfile)
    begin
      EventMachine.run do
        
        EventMachine::add_periodic_timer(5) {puts 'ping'}
        
        EventMachine::file_tail(logfile) do |filetail, line|
          puts line
        end
      end
    rescue Interrupt
      # hit ctrl-c
    end    
  end
end