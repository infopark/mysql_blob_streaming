require 'rake/clean'
require 'rake/testtask'
require 'rake/gempackagetask'
require 'yaml'

GEM_FILE = "mysql_blob_streaming-#{File.read('./version').chomp}.gem"
CLEAN.include("*.so", "*.bundle", "*.o", "Makefile", "mkmf.log")

def platform
  case RUBY_PLATFORM
  when /linux/
    "linux"
  when /darwin/
    "darwin"
  else
    raise "unsupported platform: #{RUBY_PLATFORM}"
  end
end

def bits
  1.size * 8
end

def os_type
  "#{platform}#{bits}"
end

def shared_object_file_extension
  case platform
  when 'linux'
    'so'
  when 'darwin'
    'bundle'
  end
end

task :default => :test
task :cruise => :test

desc "Create GEM for #{os_type}"
task :gem => [:clean, :compile, :test] do
  sh "env SHARED_OBJECT_FILE_EXTENSION=#{shared_object_file_extension} gem build gemspec.rb"
  mkdir_p os_type
  mv GEM_FILE, os_type
end

namespace :gem do
  desc "Install GEM for #{os_type}"
  task :install => :gem do
    sh "sudo gem install #{os_type}/#{GEM_FILE}"
  end
end

task :test => [:compile, :prepare_test_db]
Rake::TestTask.new do |t|
  t.test_files = FileList["test/test.rb"]
  t.verbose = true
end

task :prepare_test_db do
  database_config = YAML::load_file("test/database.yml")
  if %x(mysql -uroot -e 'show databases' --batch).split.include?(database_config['database'])
    sh "mysqladmin", "-uroot", "--force", "drop", database_config['database']
  end
  sh "mysqladmin", "-uroot", "create", database_config['database']
  sh "mysql", "-uroot", "-e", "grant all on #{database_config['database']}.* to '#{database_config['username']}'@'localhost' identified by '#{database_config['password']}'"
end

desc 'Compile C source files'
task :compile => 'Makefile' do
  sh 'make'
end

file 'Makefile' => ['extconf.rb', 'Rakefile'] do
  ruby "extconf.rb"
  if platform == 'darwin'
    mf = File.read("Makefile")
    open("Makefile", "w") do |f|
      f << mf.gsub(/-ppc/, '').gsub(/-arch i386/, '')
    end
  end
end

desc 'Update SQL-dump'
task :update_dump do
  rm_f "#{MY_DIR}/test/fixtures.sql"
  Rake::Task[:test].invoke
end
