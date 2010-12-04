task :default => [:package]


task :package => [:package_real]  do
end

task :package_real do
  system("gem build logtrend.gemspec")
end

task :publish do
  latest_gem = %x{ls -t logtrend*.gem}.split("\n").first
  system("gem push #{latest_gem}")
end