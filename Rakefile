require 'rake/testtask'
require 'rake/clean'
require 'yaml'

NAME = "mysql_blob_streaming"

file "lib/#{NAME}/#{NAME}.so" => Dir.glob("ext/#{NAME}/*{.rb,.c}") do
  Dir.chdir("ext/#{NAME}") do
    ruby "extconf.rb"
    sh "make"
  end
  mkdir_p "lib/#{NAME}"
  cp FileList["ext/#{NAME}/#{NAME}.{so,bundle}"], "lib/#{NAME}"
end

task :test => "lib/#{NAME}/#{NAME}.so"
task :test => :prepare_test_db

CLEAN.include('ext/**/*.{o,log,so,bundle}')
CLEAN.include('ext/**/Makefile')
CLEAN.include('ext/**/conftest*')
CLOBBER.include('lib/**/*.{so,bundle}')

Rake::TestTask.new do |t|
  t.test_files = FileList["test/test.rb"]
end

desc "Run tests"
task :default => :test
task :cruise => :test

task :prepare_test_db do
  database_config = YAML::load_file("test/database.yml")
  if %x(mysql -uroot -e 'show databases' --batch).split.include?(database_config['database'])
    sh "mysqladmin", "-uroot", "--force", "drop", database_config['database']
  end
  sh "mysqladmin", "-uroot", "create", database_config['database']
  sh "mysql", "-uroot", "-e", "grant all on #{database_config['database']}.* to '#{database_config['username']}'@'localhost' identified by '#{database_config['password']}'"
end
