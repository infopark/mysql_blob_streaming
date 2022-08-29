require "mkmf"

additional_mysql_include_dirs = [
    '/usr/local/mysql/include',
    '/usr/local/include/mysql',
    '/usr/include/mysql']
additional_mysql_lib_dirs = additional_mysql_include_dirs.map{
    |d| d.sub('include', 'lib')}

find_header('mysql.h', *additional_mysql_include_dirs)
find_header('errmsg.h', *additional_mysql_include_dirs)
find_library('mysqlclient', nil, *additional_mysql_lib_dirs)

if have_header('mysql.h')
  prefix = nil
elsif have_header('mysql/mysql.h')
  prefix = 'mysql'
else
  asplode 'mysql.h'
end
mysql_h = [prefix, 'mysql.h'].compact.join('/')
# my_bool is replaced by C99 bool in MySQL 8.0, but we want
# to retain compatibility with the typedef in earlier MySQLs.
have_type('my_bool', mysql_h)

# --no-undefined forces us to link against libruby
def remove_no_undefined(ldflags)
  ldflags.gsub("-Wl,--no-undefined", "")
end

with_ldflags("#{remove_no_undefined($LDFLAGS)}") { true }

# Do NOT link against libruby
$LIBRUBYARG = ""

create_makefile("mysql_blob_streaming/mysql_blob_streaming")
