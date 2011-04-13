# A blob streaming extension for the native Ruby-MySQL adaptor.

It provides the module MysqlBlobStreaming, which gives the adaptor the ability
of streaming blobs right out of the MySQL database.

(c) 2008-2011 Infopark AG. See MIT-LICENSE for licensing details.

## Dependencies

  * Ruby-headers
  * MySQL-headers
  * [Native Ruby-MySQL adaptor](http://www.tmtm.org/en/mysql/ruby)

## Building

    rake build
    gem build mysql_blob_streaming.gemspec

## Installation

Install it like any other Gem:

    gem install mysql_blob_streaming-X.X.X.gem

Run it with root privileges if needed.
