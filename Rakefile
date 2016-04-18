# require "bundler/gem_tasks"
# require "rspec/core/rake_task"

# RSpec::Core::RakeTask.new(:spec)

# task :default => :spec

task :default => :make

# Generating parser
file 'lib/regtest/front/parser.rb' => 'lib/regtest/front/parser.y' do
  puts 'making tst-reg-parser.rb'
  sh 'racc lib/regtest/front/parser.y -o lib/regtest/front/parser.rb'
end

# Generating bracket parser
file 'lib/regtest/front/bracket-parser.rb' => 'lib/regtest/front/bracket-parser.y' do
  puts 'making lib/regtest/front/bracket-parser.rb'
  sh 'racc lib/regtest/front/bracket-parser.y -o lib/regtest/front/bracket-parser.rb'
end

# Generating Unicode parser
file 'lib/regtest/front/unicode.rb' => 'lib/pre-unicode.rb' do
  puts "making tst-reg-parse-unicode.rb"
  sh 'ruby  lib/pre-unicode.rb'
end

task :make => ['lib/regtest/front/parser.rb', 'lib/regtest/front/bracket-parser.rb', 'lib/regtest/front/unicode.rb'] do 
  puts "Rake it!"
end

task :test => :make do 
  puts "Test it!"
  sh 'ruby test.rb'
end


