#include <ruby.h>
#include <stdlib.h>

#ifdef HAVE_MYSQL_H
  #include <mysql.h>
#else
  #include <mysql/mysql.h>
#endif
#ifdef HAVE_ERRMSG_H
  #include <errmsg.h>
#else
  #include <mysql/errmsg.h>
#endif


struct mysql_stmt {
    MYSQL_STMT *stmt;
    char closed;
    struct {
        int n;
        MYSQL_BIND *bind;
        unsigned long *length;
        MYSQL_TIME *buffer;
    } param;
    struct {
        int n;
        MYSQL_BIND *bind;
        my_bool *is_null;
        unsigned long *length;
    } result;
    MYSQL_RES *res;
};


static void store_buffer(struct mysql_stmt *s, int offset_index, VALUE obj)
{
    int status = mysql_stmt_fetch_column(s->stmt, s->result.bind, 0, offset_index);
    if (status != 0) {
        rb_raise(rb_eRuntimeError, "Fetching column failed");
    }
    if (!s->result.is_null[0]) {
        if (s->result.bind[0].buffer_type == MYSQL_TYPE_BLOB) {
            rb_funcall(obj, rb_intern("handle_data"), 1, rb_str_new(s->result.bind[0].buffer,
                    s->result.bind[0].buffer_length));
        } else {
            rb_raise(rb_eRuntimeError, "wrong buffer_type (must be: MYSQL_TYPE_BLOB): %d",
                    s->result.bind[0].buffer_type);
        }
    }
}


static int determine_blob_length(struct mysql_stmt *s)
{
    s->result.bind[0].buffer_length = 0;
    if (mysql_stmt_bind_result(s->stmt, s->result.bind) != 0) {
        rb_raise(rb_eRuntimeError, "Could not determine the blob length: bind failed");
    }
    int status = mysql_stmt_fetch(s->stmt);
    // MYSQL_DATA_TRUNCATED is returned if MYSQL_REPORT_DATA_TRUNCATION connection option is set
    if (status != 0 && status != MYSQL_DATA_TRUNCATED) {
        rb_raise(rb_eRuntimeError, "Could not determine the blob length: fetch failed");
    }
    return *s->result.bind[0].length;
}


static VALUE stmt_fetch_and_write(VALUE obj, VALUE rb_buffer_length)
{
    int buffer_length = FIX2INT(rb_buffer_length);

    if (buffer_length == 0) {
        return 0;
    }
    if (buffer_length < 0) {
        rb_raise(rb_eRuntimeError, "buffer size must be integer >= 0");
    }

    struct mysql_stmt *s = DATA_PTR(obj);
    int blob_length = determine_blob_length(s);

    s->result.bind[0].buffer_length = buffer_length;
    if (blob_length <= s->result.bind[0].buffer_length) {
        s->result.bind[0].buffer_length = blob_length;
        store_buffer(s, 0, obj);
    } else {
        long loops = abs(blob_length / s->result.bind[0].buffer_length);
        long i;
        for (i = 0; i < loops; ++i) {
            store_buffer(s, i * s->result.bind[0].buffer_length, obj);
        }
        int old_bufflen = s->result.bind[0].buffer_length;
        int new_bufflen = blob_length % s->result.bind[0].buffer_length;
        if (new_bufflen) {
            s->result.bind[0].buffer_length = new_bufflen;
            store_buffer(s, loops * old_bufflen, obj);
        }
    }
    return Qnil;
}


void Init_mysql_blob_streaming()
{
    VALUE rb_mMysqlBlobStreaming = rb_define_module("MysqlBlobStreaming");
    rb_define_method(rb_mMysqlBlobStreaming, "stream", stmt_fetch_and_write, 1);
}


