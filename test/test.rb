MY_DIR = File.dirname(__FILE__)
FIX_DIR = "#{MY_DIR}/fixtures"
TMP_DIR = "#{MY_DIR}/tmp"

require 'rubygems'
require 'test/unit'
require 'fileutils'
require 'mysql'
require "#{MY_DIR}/fixtures"
require "#{MY_DIR}/../mysql_blob_streaming"

Fixtures.insert

class MysqlBlobStreamingTest < Test::Unit::TestCase
  def setup
    FileUtils.rm_rf TMP_DIR
    FileUtils.mkdir TMP_DIR

    mysql_args = YAML::load_file("#{MY_DIR}/database.yml")
    @mysql = Mysql.new(
      'localhost',
      mysql_args['username'],
      mysql_args['password'],
      mysql_args['database']
    )
    @stmt = @mysql.prepare 'SELECT data FROM blobs WHERE name = ?'

    class << @stmt
      include MysqlBlobStreaming

      attr_accessor :file

      def counter; @counter; end
      def reset; @counter = 0; end

      def handle_data(data)
        @counter ||= 0;
        @counter = @counter + 1
        file << data
      end
    end
  end

  def teardown
    @mysql.close if @mysql
    @stmt.close if @stmt
    FileUtils.rm_rf TMP_DIR
  end

  def test_buffer_is_null
    output = output_of 'first'
    stream 'first', output, 0
    assert_equal('', File.read(output))
  end

  def test_buffer_is_less_than_null
    output = output_of 'first'
    @stmt.file = File.new(output, 'w')
    @stmt.execute 'first'

    assert_raise(RuntimeError){@stmt.stream -123}
  end

  def test_blob_data_is_null
    output = output_of 'empty'
    stream 'empty', output
    assert_equal('', File.read(output))
  end

  def test_buffer_has_specified_size
    output = output_of 'first'
    input_size = File.size("#{FIX_DIR}/first")

    stream 'first', output, 1
    assert_equal(input_size, @stmt.counter)

    stream('first', output, input_size){|stmt| stmt.reset}
    assert_equal(1, @stmt.counter)
  end

  def test_stream_blob_less_than_buffer
    input, output = io_of 'first'
    stream('first', output, File.size(input) * 100)
    assert_equal(File.read(input), File.read(output))
  end

  def test_stream_blob_bigger_than_buffer
    input, output = io_of 'first'
    stream('first', output, File.size(input) / 100)
    assert_equal(File.read(input), File.read(output))
  end

  def test_stream_blob_almoust_equal_to_buffer_but_less
    input, output = io_of 'first'
    stream('first', output, File.size(input) - 1)
    assert_equal(File.read(input), File.read(output))
  end

  def test_stream_blob_almoust_equal_to_buffer_but_bigger
    input, output = io_of 'first'
    stream('first', output, File.size(input) + 1)
    assert_equal(File.read(input), File.read(output))
  end

  def test_stream_same_blob_more_than_once
    input, output = io_of 'first'
    10.times do
      stream 'first', output
      assert_equal(File.read(input), File.read(output))
    end
  end

  def test_stream_different_blobs_serially
    input1, output1 = io_of 'first'
    input2, output2 = io_of 'second'
    10.times do
      stream 'first', output1
      assert_equal(File.read(input1), File.read(output1))
      stream 'second', output2
      assert_equal(File.read(input2), File.read(output2))
    end
  end

  def test_stream_really_big_blobs
    # Fixture functionality is not yet implemented.
    puts "\n\33[33mPending: Test RAM-usage while streaming some really big blob.\e[0m\n"
  end

  def test_stream_really_tiny_blobs
    input, output = io_of 'small'
    stream 'small', output
    assert_equal(File.read(input), File.read(output))
  end

  # Helpers
  def stream(id, output, buffer_size = 65000)
    @stmt.file = File.new(output, 'w')
    @stmt.execute id
    yield(@stmt) if block_given?
    @stmt.stream buffer_size
    @stmt.file.close
  end

  def output_of(id)
    "#{TMP_DIR}/#{id}"
  end

  def io_of(id)
    ["#{FIX_DIR}/#{id}", output_of(id)]
  end
end
