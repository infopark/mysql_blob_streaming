# encoding: UTF-8
require 'active_record'
require 'yaml'

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
    end
  end

  @@mysql_args = "-u#{@@con_args["username"]} -p#{@@con_args["password"]} #{@@con_args["database"]}"

  def self.insert
    FixtureMigration.migrate :up
    %w|first second small|.each do |name|
      Blob.create(
        name: name,
        data: File::read("#{Fixtures::MY_DIR}/fixtures/#{name}")
      )
    end
    Blob.create(name: 'empty', data: nil)
    Blob.create(name: 'hellö', data: "wörld")
  end
end
