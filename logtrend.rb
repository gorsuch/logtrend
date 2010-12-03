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
  
  def update_rrd(name, value)
    file_name = "#{name}.rrd"
    rrd = RRD::Base.new(file_name)
    if !File.exists?(file_name)
      rrd.create :start => Time.now - 10.seconds, :step => 1.minutes do
        datasource "#{name}_count", :type => :gauge, :heartbeat => 5.minutes, :min => 0, :max => :unlimited
        archive :average, :every => 5.minutes, :during => 1.year
      end
    end
    rrd.update Time.now, value
  end
  
  def start(logfile)
    begin 
      counters = reset_counters
      
      EventMachine.run do       
        EventMachine::add_periodic_timer(1) do
          puts counters.inspect
          counters.each do |name, value|
            update_rrd(name, value)
          end
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