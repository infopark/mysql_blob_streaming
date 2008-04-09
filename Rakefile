require 'rake/testtask'
require 'rake/gempackagetask'

MY_DIR = File.expand_path(File.dirname(__FILE__))
GEM_FILE = "mysql_blob_streaming-#{File.read('./version').chop}.gem"

task :default => :test

task :cruise => [:test, "gem:linux"]

task :test => :compile
Rake::TestTask.new do |t|
	t.test_files = FileList["#{MY_DIR}/test/test.rb"]
	t.verbose = true
end

desc 'Compile C source files'
task :compile do
  within_root_dir do
		sh 'touch mysql_blob_streaming.c; ruby extconf.rb; make'
		exit 1 if FileList['mysql_blob_streaming.{so,bundle}'].empty?
	end
end

%w|linux darwin|.each do |ostype|
	namespace :gem do
		desc "Create #{ostype} GEM-Package"
		task ostype.to_sym => [:test, :compile] do
			within_root_dir do
				sh "ostype='#{ostype}' gem build gemspec.rb"
				exit 1 if FileList[GEM_FILE].empty?
				FileUtils.mv GEM_FILE, "./#{ostype}"
			end
		end
	end

	namespace :install do
		desc "Install GEM on a #{ostype}"
		task ostype.to_sym => "gem:#{ostype}" do
			within_root_dir do
				sh "sudo gem install ./#{ostype}/#{GEM_FILE}"
			end
		end
	end
end

desc 'Update SQL-dump'
task :update_dump do
  FileUtils.rm_f "#{MY_DIR}/test/fixtures.sql"
	Rake::Task[:test].invoke
end

def within_root_dir
	Dir.chdir(MY_DIR){yield}
end
