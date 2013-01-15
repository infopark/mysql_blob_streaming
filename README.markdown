# A blob streaming extension for the native Ruby-MySQL2 adaptor.

It provides the module MysqlBlobStreaming, which gives the mysql2 adaptor the ability
of streaming blobs right out of the MySQL database.

(c) 2008-2012 Infopark AG. See MIT-LICENSE for licensing details.

## Usage

    require 'mysql_blob_streaming'
    require 'mysql2'

    client = Mysql2::Client.new(...)
    query = "SELECT data FROM table_name WHERE id = '23'"
    buffer_size = 1024000 # number of bytes per chunk

    MysqlBlobStreaming.stream(client, query, buffer_size) do |chunk|
      # do something with the chunk e.g. write it to file.
    end

## Dependencies

  * Ruby-headers
  * MySQL-headers
  * [mysql2 Gem](https://rubygems.org/gems/mysql2)

## Building

    gem build mysql_blob_streaming.gemspec

## Installation

Install it like any other Gem:

    gem install mysql_blob_streaming-X.X.X.gem

Run it with root privileges if needed.
