require 'mkmf'

dir_config('mysql_blob_streaming')
dir_config('mysql')

find_header('mysql.h')
find_header('errmsg.h')

create_makefile('mysql_blob_streaming')
