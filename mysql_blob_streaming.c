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

#define cMaxErrMsgLength 250
#define stmtext_raise(errmsg, context) sprintf(errmsg, "STMTEXT_ERROR: %s\n", context); \
															 				 rb_raise(rb_eRuntimeError, errmsg);

#define ERROR_CONTEXT_FETCH "while determining blob length - mysql_stmt_fetch return result was neither 0 nor MYSQL_DATA_TRUNCATED"
#define ERROR_CONTEXT_BIND "while determining blob length - mysql_stmt_bind_result return status was not 0"
#define ERROR_CONTEXT_STORE "while storing buffer - mysql_stmt_fetch_column return status was not 0"


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


static int store_buffer(struct mysql_stmt *s, int offset_index, VALUE obj);
static void handle_results(int res_bind, int res_fetch, struct mysql_stmt *s);
static int determine_blob_length(struct mysql_stmt *s);
static VALUE stmt_fetch_and_write(VALUE obj, VALUE buffer_length);


static VALUE rb_mMysqlBlobStreaming;
VALUE mysqlClass;


void Init_mysql_blob_streaming()
{
    rb_mMysqlBlobStreaming = rb_define_module("MysqlBlobStreaming");
    rb_define_method(rb_mMysqlBlobStreaming, "stream", stmt_fetch_and_write, 1);
    mysqlClass = rb_define_class("Mysql", rb_cObject);
}


static VALUE stmt_fetch_and_write(VALUE obj, VALUE rb_buffer_length)
{
		int buffer_length = FIX2INT(rb_buffer_length);

		if (buffer_length == 0) return 0;
		if (buffer_length < 0) {
				rb_raise(rb_eRuntimeError, "buffer size must be integer >= 0");
		}

    struct mysql_stmt *s = DATA_PTR(obj);
    int blob_length = determine_blob_length(s);

    s->result.bind[0].buffer_length = buffer_length;
    if (blob_length <= s->result.bind[0].buffer_length) {
        s->result.bind[0].buffer_length = blob_length;
        if (store_buffer(s, 0, obj)) {
            return Qnil;
        }
    } else {
        long loops = abs(blob_length / s->result.bind[0].buffer_length);
        long i;
        for (i = 0; i < loops; ++ i) {
            if (store_buffer(s, i * s->result.bind[0].buffer_length, obj)) {
                return Qnil;
            }
            rb_funcall(obj, rb_intern("log_progress"), 1,
                    rb_float_new(((double)i + 1.0) * s->result.bind[0].buffer_length *
                    100.0 / blob_length));
        }
        int old_bufflen = s->result.bind[0].buffer_length;
        int new_bufflen = blob_length % s->result.bind[0].buffer_length;
        if (new_bufflen) {
            s->result.bind[0].buffer_length = new_bufflen;
            if (store_buffer(s, loops * old_bufflen, obj)) {
                return Qnil;
            }
        }
    }
    rb_funcall(obj, rb_intern("log_progress"), 1, INT2FIX(100));
    return Qnil;
}


static int determine_blob_length(struct mysql_stmt *s)
{
    s->result.bind[0].buffer_length = 0;

		int res_bind  = mysql_stmt_bind_result(s->stmt, s->result.bind);
		int res_fetch = mysql_stmt_fetch(s->stmt);

		handle_results(res_bind, res_fetch, s);
    
		return *s->result.bind[0].length;
}


static void handle_results(int res_bind, int res_fetch, struct mysql_stmt *s)
{
		char errmsg[cMaxErrMsgLength];

		if (res_bind != 0) {
			stmtext_raise(errmsg, ERROR_CONTEXT_BIND);
		}
		// MYSQL_DATA_TRUNCATED is returned if MYSQL_REPORT_DATA_TRUNCATION connection option is set
		if (res_fetch !=0 && res_fetch != MYSQL_DATA_TRUNCATED) {
			stmtext_raise(errmsg, ERROR_CONTEXT_FETCH);
		}
}


static int store_buffer(struct mysql_stmt *s, int offset_index, VALUE obj)
{
    int status = mysql_stmt_fetch_column(s->stmt, s->result.bind, 0, offset_index);
    if (status != 0) {
				char errmsg[cMaxErrMsgLength];
				stmtext_raise(errmsg, ERROR_CONTEXT_STORE);
    }
    if (!s->result.is_null[0]) {
        if (s->result.bind[0].buffer_type == MYSQL_TYPE_BLOB) {
            rb_funcall(obj, rb_intern("handle_data"), 1, rb_str_new(s->result.bind[0].buffer,
                  s->result.bind[0].buffer_length));
        } else {
            rb_raise(rb_eTypeError, "wrong buffer_type (must be: MYSQL_TYPE_BLOB): %d",
                s->result.bind[0].buffer_type);
        }
    }
    return 0;
}
