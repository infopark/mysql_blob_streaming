begin
  require "mysql_blob_streaming_stream64"
rescue LoadError => e1
  begin
    require "mysql_blob_streaming_stream"
  rescue LoadError => e2
    raise "Could neither load mysql_blob_streaming_stream (#{e2.message}) " +
        "nor mysql_blob_streaming_stream64 (#{e1.message})."
  end
end
