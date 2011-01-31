require 'mkmf'

dir_config('mysql_blob_streaming')
dir_config('mysql')

additional_mysql_include_dirs = [
    '/usr/local/mysql/include',
    '/usr/include/mysql']
additional_mysql_lib_dirs = additional_mysql_include_dirs.map{
    |d| d.sub('include', 'lib')}

find_header('mysql.h', *additional_mysql_include_dirs)
find_header('errmsg.h', *additional_mysql_include_dirs)
# find_library('mysqlclient', mysql_stmt_fetch_column, *additional_mysql_lib_dirs)
find_library('mysqlclient', nil, *additional_mysql_lib_dirs)

# --no-undefined forces us to link against libruby
def remove_no_undefined(ldflags)
  ldflags.gsub("-Wl,--no-undefined", "")
end

with_ldflags("#{remove_no_undefined($LDFLAGS)}") { true }

# Do NOT link against libruby
$LIBRUBYARG = ""

create_makefile('mysql_blob_streaming_stream')