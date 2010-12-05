Gem::Specification.new do |spec|
  files = []
  dirs = %w{lib samples}
  dirs.each do |dir|
    files += Dir["#{dir}/**/*"]
  end

  rev = Time.now.strftime("%Y%m%d%H%M%S")
  spec.name = "logtrend"
  spec.version = "0.9.#{rev}"
  spec.summary = "logtrend - an event-driven http log parser that generates rrd graphs"
  spec.description = "logtrend is an HTTP log parser built on top of event machine, generating rrd graphs of usage matching patterns you define."
  spec.add_dependency("eventmachine")
  spec.add_dependency("eventmachine-tail")
  spec.add_dependency("rrd-ffi")
  spec.files = files
  spec.require_paths << "lib"

  spec.author = "Michael Gorsuch"
  spec.email = "michael.gorsuch@gmail.com"
  spec.homepage = "https://github.com/gorsuch/logtrend"
end
