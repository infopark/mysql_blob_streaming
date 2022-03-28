All notable changes to this project will be documented in this file.

This gem lives here https://github.com/infopark/mysql_blob_streaming.
## v2.5.0 - 2022-03-22

### Reason to make changes

- make gem compatible with MariaDB 10.2 and 10.3 (see Bug https://bugs.mysql.com/bug.php?id=87337)
- Tested with the following versions:
  - MySQL 5.6
  - MySQL 5.7
  - MySQL 8.0.2
  - MariaDB 10.2
  - MariaDB 10.3

### Compatible changes

- add condition to check MySQL version in /ext/mysql_blob_streaming/mysql_blob_streaming.c
  #if MYSQL_VERSION_ID >=80000 && MYSQL_VERSION_ID <80030
    typedef bool my_bool;
  #endif


## v2.4.0 - 2021-03-23

### Reason to make changes

- make gem compatible with MySQL version ~> 8.0.1

### Compatible changes

- add condition to check MySQL version in /ext/mysql_blob_streaming/mysql_blob_streaming.c
  #if MYSQL_VERSION_ID >=80000
    typedef bool my_bool;
  #endif

- remove deprecated 'spec.has_rdoc' from mysql_blob_streaming.gemspec
