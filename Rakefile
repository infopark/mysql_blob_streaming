require 'rake/clean'
require 'rake/testtask'
require 'rake/gempackagetask'
require 'yaml'

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

task :default => :test
task :cruise => :test

task :test => [:build, :prepare_test_db]
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

task :build => [:clean, :compile] do
  Dir["*.so", "*.dll", "*.bundle"].each do |file|
    new_name = file.pathmap("%{$,*}n%x") { "64" if os_type == "linux64" }
    mv file, "lib/#{new_name}", :verbose => true
  end
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
