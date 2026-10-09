require 'bundler/gem_tasks'
require 'rake/testtask'

# The specs talk to a real Kestrel 2.4.1 on KJESS_MEMCACHE_PORT (default 33122): start one before running them.
# (`rake kestrel:start` can unpack and start one if the download URL in tasks/kestrel.rake still works.)
Rake::TestTask.new(:test) do |t|
  t.libs = %w[lib spec .]
  t.pattern = 'spec/**/*_spec.rb'
  t.warning = false
end

task :default => :test

# Optional helpers to download/start/stop a Kestrel for the specs
$LOAD_PATH << '.' unless $LOAD_PATH.include?('.')
load 'tasks/kestrel.rake'
