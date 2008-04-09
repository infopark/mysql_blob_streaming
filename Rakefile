require 'rake/testtask'
require 'rake/gempackagetask'

MY_DIR = File.expand_path(File.dirname(__FILE__))

task :default => :test

task :cruise => [:test, :gem]

task :test => :compile
Rake::TestTask.new do |t|
	t.test_files = FileList["#{MY_DIR}/test/test.rb"]
	t.verbose = true
end

desc 'Compile C source files'
task :compile => :clean do
  in_root_dir do
		sh 'ruby extconf.rb; make'
		exit 1 unless File.exist? 'mysql_blob_streaming.so'
	end
end

desc 'Remove files produced by compiling' 
task :clean do
  in_root_dir do
		%w|Makefile mysql_blob_streaming.so mysql_blob_streaming.o mkmf.log|.each do |file|
			FileUtils.rm_f file
		end
	end
end

desc 'Create GEM-Package'
task :gem => [:test, :clean, :compile] do
  in_root_dir do
		sh 'gem build gemspec.rb'
		exit 1 if FileList['mysql_blob_streaming-*.gem'].empty?
	end
end

desc 'Install GEM'
task :install => :gem do
  in_root_dir do
		%w|uninstall install|.each do |action|
			sh "sudo gem #{action} mysql_blob_streaming"
		end
	end
end

desc 'Update SQL-dump'
task :update_dump do
  FileUtils.rm_f "#{MY_DIR}/test/fixtures.sql"
	Rake::Task[:test].invoke
end

def in_root_dir
	Dir.chdir(MY_DIR){yield}
end
