require 'rubygems'
require 'eventmachine'
require 'eventmachine-tail'
require 'rrd'
require 'logger'

class LogTrend
  attr_accessor :trends
  attr_accessor :graphs
  
  def initialize
    trends = {}
    graphs = {}
    @logger = Logger.new(STDERR)
    @logger.level = ($DEBUG and Logger::DEBUG or Logger::WARN)
  end
  
  def reset_counters
    counters = {}
    trends.keys.each do |k|
      counters[k] = 0
    end
    counters
  end
  
  def update_rrd(rrd_dir,name, value)
    file_name = File.join(rrd_dir,"#{name}.rrd")
    rrd = RRD::Base.new(file_name)
    if !File.exists?(file_name)
      rrd.create :start => Time.now - 10.seconds, :step => 1.minutes do
        datasource "#{name}_count", :type => :gauge, :heartbeat => 5.minutes, :min => 0, :max => :unlimited
        archive :average, :every => 5.minutes, :during => 1.year
      end
    end
    rrd.update Time.now, value
  end
  
  def build_graph(graphs_dir, rrd_dir, name, data)
    RRD.graph File.join(graphs_dir,"#{name}.png"), :title => name, :width => 800, :height => 250, :color => ["FONT#000000", "BACK#FFFFFF"] do
      data.each do |name, color|
        area File.join(rrd_dir,"#{name}.rrd"), "#{name}_count" => :average, :color => color, :label => name.to_s
      end
    end
  end
  
  def start(logfile,rrd_dir,graphs_dir)
    begin
      rrd_dir = rrd_dir
      graphs_dir = graphs_dir      
      counters = reset_counters
      
      EventMachine.run do       
        EventMachine::add_periodic_timer(1.minute) do
          @logger.debug "#{Time.now} #{counters.inspect}"
          counters.each {|name, value| update_rrd(rrd_dir,name, value)}            
          graphs.each {|name, data| build_graph(graphs_dir, rrd_dir, name, data)}
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
  
  def self.start(logfile, rrd_dir, graphs_dir, &block)
    l = LogTrend.new
    yield l if block
    l.start logfile, rrd_dir, graphs_dir
  end
end