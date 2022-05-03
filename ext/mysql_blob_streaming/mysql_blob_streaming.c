#include <ruby.h>
#include <stdlib.h>

#include <mysql.h>
#include <errmsg.h>

#if MYSQL_VERSION_ID >=80000 && MYSQL_VERSION_ID <80030
  #include <stdbool.h>
  typedef bool my_bool;
#endif

typedef struct {
  VALUE encoding;
  VALUE active_thread;
  long server_version;
  int reconnect_enabled;
  int connect_timeout;
  int active;
  int connected;
  int initialized;
  int refcount;
  int freed;
  MYSQL *client;
} mysql_client_wrapper;


static MYSQL * mysql_connection(VALUE rb_mysql2_client)
{
    mysql_client_wrapper *wrapper;
    Data_Get_Struct(rb_mysql2_client, mysql_client_wrapper, wrapper);
    return wrapper->client;
}


static MYSQL_STMT * prepare_and_execute_stmt_with_query(MYSQL *conn, char *query)
{
    MYSQL_STMT *stmt = mysql_stmt_init(conn);
    if (stmt == NULL) {
        rb_raise(rb_eRuntimeError, "Could not initialize prepared statement!");
    }

    int prepare_error = mysql_stmt_prepare(stmt, query, strlen(query));
    if (prepare_error) {
        rb_raise(rb_eRuntimeError, "Could not prepare statement! Error Code: %d", prepare_error);
    }

    long nr_params = mysql_stmt_param_count(stmt);
    if (nr_params) {
        rb_raise(rb_eRuntimeError, "Query contains %lu placeholders. 0 are allowed!", nr_params);
    }

    int exec_code = mysql_stmt_execute(stmt);
    if (exec_code) {
        rb_raise(rb_eRuntimeError, "Could not execute statement. MySQL error code: %d", exec_code);
    }

    return stmt;
}


static void store_buffer(MYSQL_STMT *stmt, int offset_index, MYSQL_BIND *bind, int chunk_length, VALUE block, VALUE obj)
{
    int status = mysql_stmt_fetch_column(stmt, bind, 0, offset_index);
    if (status != 0) {
        rb_raise(rb_eRuntimeError, "Fetching column failed");
    }
    if (!*bind->is_null) {
        if (bind->buffer_type == MYSQL_TYPE_BLOB) {
            if(RTEST(block)) {
                rb_funcall(block, rb_intern("call"), 1, rb_str_new(bind->buffer, chunk_length));
            } else {
                rb_raise(rb_eArgError, "a block is required");
            }
        } else {
            rb_raise(rb_eRuntimeError, "wrong buffer_type (must be: MYSQL_TYPE_BLOB): %d",
                    bind->buffer_type);
        }
    }
}


static int determine_blob_length(MYSQL_STMT *stmt, MYSQL_BIND *bind)
{
    int original_buffer_length = bind->buffer_length;
    bind->buffer_length = 0;

    if (mysql_stmt_bind_result(stmt, bind) != 0) {
        rb_raise(rb_eRuntimeError, "determine_blob_length2 Could not determine the blob length: bind failed");
    }
    int status = mysql_stmt_fetch(stmt);
    // MYSQL_DATA_TRUNCATED is returned if MYSQL_REPORT_DATA_TRUNCATION connection option is set
    if (status != 0 && status != MYSQL_DATA_TRUNCATED) {
        rb_raise(rb_eRuntimeError, "determine_blob_length2 Could not determine the blob length: fetch failed");
    }

    bind->buffer_length = original_buffer_length;
    return *bind->length;
}


static void loop_store_buffer(MYSQL_STMT *stmt, MYSQL_BIND *bind, int total_blob_length, VALUE block, VALUE obj)
{
    long loops = abs(total_blob_length / bind->buffer_length);
    long i;
    for (i = 0; i < loops; ++i) {
        store_buffer(stmt, i * bind->buffer_length, bind, bind->buffer_length, block, obj);
    }
    int new_bufflen = total_blob_length % bind->buffer_length;
    if (new_bufflen) {
        store_buffer(stmt, loops * bind->buffer_length, bind, new_bufflen, block, obj);
    }
}


static MYSQL_BIND * build_result_bind(MYSQL_STMT *stmt, int buffer_length)
{
    MYSQL_BIND *bind = (MYSQL_BIND *)calloc(1, sizeof(MYSQL_BIND));
    bind->length = (unsigned long *)calloc(1, sizeof(unsigned long));
    bind->is_null = (my_bool *)calloc(1, sizeof(my_bool));
    bind->buffer_length = buffer_length;
    bind->buffer = malloc(buffer_length);

    MYSQL_RES *result_set = mysql_stmt_result_metadata(stmt);
    if ((result_set != NULL) && (mysql_num_fields(result_set) >= 1)) {
        MYSQL_FIELD *columns = mysql_fetch_fields(result_set);
        bind->buffer_type = columns->type;
    }

    return bind;
}


static void free_result_bind(MYSQL_BIND *bind)
{
    if (bind != NULL) {
        free(bind->buffer);
        free(bind->length);
        free(bind->is_null);
        free(bind);
    }
}


// ruby interface:
// MysqlBlobStreaming.stream(mysql2_client, query, buffer_length, &block)
static VALUE stmt_fetch_and_write(int argc, VALUE *argv, VALUE self)
{
    VALUE rb_mysql2_client;
    VALUE rb_query;
    VALUE rb_buffer_length;
    VALUE rb_block;
    rb_scan_args(argc, argv, "3&", &rb_mysql2_client, &rb_query, &rb_buffer_length, &rb_block);

    int buffer_length = FIX2INT(rb_buffer_length);

    if (buffer_length == 0) {
        return 0;
    }
    if (buffer_length < 0) {
        rb_raise(rb_eRuntimeError, "buffer size must be integer >= 0");
    }

    char *query = RSTRING_PTR(rb_query);

    MYSQL *conn = mysql_connection(rb_mysql2_client);
    MYSQL_STMT *stmt = prepare_and_execute_stmt_with_query(conn, query);
    MYSQL_BIND *bind = build_result_bind(stmt, buffer_length);

    int total_blob_length = determine_blob_length(stmt, bind);
    loop_store_buffer(stmt, bind, total_blob_length, rb_block, self);

    mysql_stmt_close(stmt);
    free_result_bind(bind);
    return Qnil;
}


void Init_mysql_blob_streaming()
{
    VALUE rb_mMysqlBlobStreaming = rb_define_class("MysqlBlobStreaming", rb_cObject);
    rb_define_singleton_method(rb_mMysqlBlobStreaming, "stream", stmt_fetch_and_write, -1);
}
