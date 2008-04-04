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
	Dir.chdir MY_DIR do
		sh 'ruby extconf.rb; make'
		exit 1 unless File.exist? 'mysql_blob_streaming.so'
	end
end

desc 'Remove files produced by compiling' 
task :clean do
	Dir.chdir MY_DIR do
		%w|Makefile mysql_blob_streaming.so mysql_blob_streaming.o mkmf.log|.each do |file|
			FileUtils.rm_f file
		end
	end
end

desc 'Create GEM-Package'
task :gem => [:test, :clean, :compile] do
	Dir.chdir MY_DIR do
		sh 'gem build gemspec.rb'
		exit 1 if FileList['mysql_blob_streaming-*.gem'].empty?
	end
end

desc 'Install GEM'
task :install => :gem do
	Dir.chdir MY_DIR do
		%w|uninstall install|.each do |action|
			sh "sudo gem #{action} mysql_blob_streaming"
		end
	end
end

desc 'Update SQL-dump'
task :update_dump do
	dump = "#{MY_DIR}/test/fixtures.sql" 

	if File.exist?(dump)
		FileUtils.mv dump, "#{dump}.bak"
	end

	Rake::Task[:test].invoke

	if File.exist?(dump)
		FileUtils.rm "#{dump}.bak"
	else
		FileUtils.mv "#{dump}.bak", dump
	end
end
