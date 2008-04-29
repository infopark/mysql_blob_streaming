require 'rake/testtask'
require 'rake/gempackagetask'

GEM_FILE = "mysql_blob_streaming-#{File.read('./version').chomp}.gem"

task :default => :test

task :cruise => :test

task :test => :compile
Rake::TestTask.new do |t|
  t.test_files = FileList["test/test.rb"]
  t.verbose = true
end

file 'Makefile' => ['extconf.rb', 'Rakefile'] do
  ruby "extconf.rb"
  sh 'perl -i -pe "s/-ppc//g" Makefile'
end

desc 'Compile C source files'
task :compile => 'Makefile' do
  sh 'make'
end

task :clean do
  rm_f FileList["*.so", "*.bundle", "*.dll", "*.o", "Makefile", "mkmf.log"], :verbose => true
end

%w|linux32 linux64 darwin32|.each do |ostype|
  namespace :gem do
    desc "Create #{ostype} GEM-Package"
    task ostype => :test do
      sh "ostype='#{ostype}' gem build gemspec.rb"
      mkdir_p ostype
      mv GEM_FILE, ostype
    end
  end

  namespace :install do
    desc "Install GEM on a #{ostype}"
    task ostype => "gem:#{ostype}" do
      sh "sudo gem install #{ostype}/#{GEM_FILE}"
    end
  end
end

desc 'Update SQL-dump'
task :update_dump do
  rm_f "#{MY_DIR}/test/fixtures.sql"
  Rake::Task[:test].invoke
end

