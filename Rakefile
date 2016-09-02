require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

# task :default => :spec

task :default => [:make, :spec]

# Generating parser
file 'lib/regextest/front/parser.rb' => 'lib/regextest/front/parser.y' do
  puts 'making regextest/front/parser.rb'
  sh 'racc lib/regextest/front/parser.y -o lib/regextest/front/parser.rb'
end

# Generating bracket parser
file 'lib/regextest/front/bracket-parser.rb' => 'lib/regextest/front/bracket-parser.y' do
  puts 'making regextest/front/bracket-parser.rb'
  sh 'racc lib/regextest/front/bracket-parser.y -o lib/regextest/front/bracket-parser.rb'
end

# Generating Unicode parser
file 'lib/regextest/unicode.rb' => 'lib/pre/unicode.rb' do
  puts "making regextest/unicode.rb"
  sh 'ruby  lib/pre/unicode.rb'
end

# Generating case-folding mapping
file 'lib/regextest/front/case-folding.rb' => 'lib/pre/case-folding.rb' do
  puts "making regextest/front/case-folding.rb"
  sh 'ruby  lib/pre/case-folding.rb'
end

# Generating regression test suite
file 'spec/regression_spec.rb' => 'lib/pre/generate-spec.rb' do
  puts "making spec/regression_spec.rb"
  sh 'ruby  lib/pre/generate-spec.rb'
end

# Generating documents
file 'doc/index.html' => ['lib/regextest.rb', 'lib/regextest/regexp.rb', 'README.md'] do
  puts "making document for Regextest"
  sh 'yardoc lib/regextest.rb lib/regextest/regexp.rb'
end

task :make =>
        ['lib/regextest/front/parser.rb',
         'lib/regextest/front/bracket-parser.rb',
         'lib/regextest/front/case-folding.rb',
         'lib/regextest/unicode.rb',
         'spec/regression_spec.rb',
         'doc/index.html',
        ] do 
  puts "Rake it!"
end

task :test => :make do 
  puts "Test it!"
  sh 'ruby test.rb'
end


