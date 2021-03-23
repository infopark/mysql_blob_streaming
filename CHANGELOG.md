All notable changes to this project will be documented in this file.

This gem lives here https://github.com/infopark/mysql_blob_streaming.

## v2.4.0 - 2021-03-23

### Reason to make changes

- make gem compatible with MySQL version ~> 8.0.1  

### Compatible changes

- replace deprecated for MySql 8.0 my_bool to bool type in /ext/mysql_blob_streaming/mysql_blob_streaming.c
- remove deprecated 'spec.has_rdoc' from mysql_blob_streaming.gemspec
