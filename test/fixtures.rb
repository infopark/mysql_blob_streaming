require 'rubygems'
require 'active_record'

module Fixtures
	MY_DIR = File.dirname(__FILE__)

	@@con_args = YAML::load_file("#{MY_DIR}/database.yml")
	ActiveRecord::Base.establish_connection @@con_args

	class Blob < ActiveRecord::Base; end

	class FixtureMigration < ActiveRecord::Migration
		def self.up
			create_table :blobs do |t|
				t.column :name, :string
				t.column :data, :longblob
			end

			%w|first second small|.each do |name|
				Blob.create(
					:name => name,
					:data => File::read("#{Fixtures::MY_DIR}/fixtures/#{name}")
				)
			end
			Blob.create(:name => 'empty', :data => nil)
		end

		def self.down
			drop_table :blobs
		end
	end

	@@mysql_args = "-u#{@@con_args["username"]} -p#{@@con_args["password"]} #{@@con_args["database"]}"
	@@dump_file = "#{MY_DIR}/fixtures.sql"

	def self.update
		puts "\n\t\33[33mWARNING: this could defy your RAM, so be pationed!\e[0m\n\n"

		FixtureMigration.migrate :down
		FixtureMigration.migrate :up

		%x|mysqldump #{@@mysql_args} > #{@@dump_file}|
	end

	def self.insert
		if File.exist? @@dump_file
			%x|mysql #{@@mysql_args} < #{@@dump_file}|
		else; update; end
	end
end
