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
  
  def build_graph(name, data)
    RRD.graph "#{name}.png", :title => name, :width => 800, :height => 250, :color => ["FONT#000000", "BACK#FFFFFF"] do
      data.each do |name, color|
        area "#{name}.rrd", "#{name}_count" => :average, :color => color, :label => name.to_s
      end
    end
  end
  
  def start(logfile)
    begin 
      counters = reset_counters
      
      EventMachine.run do       
        EventMachine::add_periodic_timer(60) do
          puts counters.inspect
          counters.each {|name, value| update_rrd(name, value)}            
          graphs.each {|name, data| build_graph(name, data)}
          counters = reset_counters
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