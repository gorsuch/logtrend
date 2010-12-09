require 'rubygems'
require 'eventmachine'
require 'eventmachine-tail'
require 'rrd'
require 'logger'
require 'erb'

module LogTrend
  class Base
    # This sets the directory where graphs should be stored.
    attr_accessor :graphs_dir

    # This sets the directory where your RRD files will rest.
    attr_accessor :rrd_dir

    # This sets the logger to use. Must be something like a Logger object.
    attr_accessor :logger

    # This sets the HTML file template for the generated index.html file.
    # The String here will pass through ERB, with self being set as the binding.
    attr_accessor :template

    # Defines the amount of time between each updates, given in seconds. Default value is 60 seconds.
    #
    # From the rrdcreate(2) manual page:
    #
    #     Specifies the base interval in seconds with which data will be fed into the RRD.
    #
    #
    # @see http://www.mrtg.org/rrdtool/doc/rrdcreate.en.html
    attr_accessor :step

    # Defines the amount of time between updates that will mark a value unknown.
    #
    # From the rrdcreate(2) manual page:
    #
    #     heartbeat defines the maximum number of seconds that may pass between two updates of this data source before the value of the data source is assumed to be *UNKNOWN*.
    #
    # @see http://www.mrtg.org/rrdtool/doc/rrdcreate.en.html
    attr_accessor :heartbeat

    def initialize(options={})
      set_defaults

      options.each do |key, val|
        send("#{key}=", val)
      end
    end

    def add_trend(name, &block)
      throw "D'oh! No block." unless block_given?
      @trends[name] = block
    end

    def add_graph(name, &block)
      throw "D'oh! No block." unless block_given?
      graph = Graph.new(name)
      yield graph
      @graphs << graph
    end
    #
    # This is the preferred entry point.
    def self.run(logfile, options={}, &block)
      throw "D'oh! No block." unless block_given?
      l = Base.new(options)
      yield l
      l.run logfile
    end

    def run(logfile)
      counters = reset_counters

      EventMachine.run do
        EventMachine::add_periodic_timer(step) do
          @logger.debug "#{Time.now} #{counters.inspect}"
          counters.each {|name, value| update_rrd(name, value)}
          @graphs.each {|graph| build_graph(graph)}
          build_page
          counters = reset_counters
        end

        EventMachine::file_tail(logfile) do |filetail, line|
          @trends.each do |name, block|
            counters[name] += 1 if block.call(line)
          end
          @logger.debug counters.inspect
        end
      end
    end

    private

    def reset_counters
      counters = {}
      @trends.keys.each do |k|
        counters[k] = 0
      end
      counters
    end

    def update_rrd(name, value)
      file_name = File.join(@rrd_dir,"#{name}.rrd")
      rrd = RRD::Base.new(file_name)
      if !File.file?(file_name)
        rrd.create :start => Time.now - 10.seconds, :step => step do
          datasource "#{name}_count", :type => :gauge, :heartbeat => heartbeat, :min => 0, :max => :unlimited
          archive :average, :every => 5.minutes, :during => 1.year
        end
      end
      rrd.update Time.now, value
    end

    def build_graph(graph)
      rrd_dir = @rrd_dir
      RRD.graph File.join(@graphs_dir,"#{graph.name}.png"), :title => graph.name, :width => 800, :height => 250, :color => ["FONT#000000", "BACK#FFFFFF"] do
        graph.points.each do |point|
          if point.style == :line
            line File.join(rrd_dir,"#{point.name}.rrd"), "#{point.name}_count" => :average, :color => point.color, :label => point.name.to_s
          elsif point.style == :area
            area File.join(rrd_dir,"#{point.name}.rrd"), "#{point.name}_count" => :average, :color => point.color, :label => point.name.to_s
          end
        end
      end
    end

    def build_page
      file_name = File.join(@graphs_dir,'index.html')
      File.open(file_name, "w") do |f|
        f << @template.result(binding)
      end
    end

    def set_defaults
      @graphs_dir = '.'
      @rrd_dir = '.'
      @trends = {}
      @graphs = []
      @logger = Logger.new(STDERR)
      @logger.level = ($DEBUG and Logger::DEBUG or Logger::WARN)

      @step = 1.minute
      @heartbeat = 5.minutes

      @template = ERB.new <<-EOF
      <html>
        <head>
          <title>logtrend</title>
        </head>
        <body>
          <% @graphs.each do |graph| %>
            <img src='<%=graph.name%>.png' />
          <% end %>
        </body>
      </html>
      EOF
    end
    private :set_defaults
  end

  class Graph

    attr_reader :points
    attr_reader :name

    def initialize(name)
      @name = name
      @points = []
    end

    def add_point(style,name,color)
      @points << GraphPoint.new(style, name, color)
    end
  end

  GraphPoint = Struct.new(:style, :name, :color)
end
