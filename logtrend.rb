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
  
  def reset_counters
    counters = {}
    trends.keys.each do |k|
      counters[k] = 0
    end
    counters
  end
  
  def start(logfile)
    begin 
      counters = reset_counters
      
      EventMachine.run do
        
        EventMachine::add_periodic_timer(1) do
          puts counters.inspect
        end
        
        EventMachine::file_tail(logfile) do |filetail, line|
          trends.each do |name, regex|
            counters[name] += 1 if line.match(regex)
          end
        end
      end
    rescue Interrupt
      # hit ctrl-c
    end    
  end
end