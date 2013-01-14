# encoding: UTF-8
MY_DIR = File.dirname(__FILE__)
FIX_DIR = "#{MY_DIR}/fixtures"
TMP_DIR = "#{MY_DIR}/tmp"
LIB_DIR = "#{MY_DIR}/../lib"

# make sure our lib is first in the load path.
# otherwise we might test against a gem installed in the system
$LOAD_PATH.unshift(LIB_DIR)

require 'test/unit'
require 'fileutils'
require "#{MY_DIR}/fixtures"
require "mysql_blob_streaming"
require 'mysql2'

Fixtures.insert

class MysqlBlobStreamingTest < Test::Unit::TestCase
  def setup
    FileUtils.rm_rf TMP_DIR
    FileUtils.mkdir TMP_DIR

    mysql_args = YAML::load_file("#{MY_DIR}/database.yml")
    @mysql = Mysql2::Client.new({
      :host => 'localhost',
      :username => mysql_args['username'],
      :password => mysql_args['password'],
      :database => mysql_args['database'],
    })
  end

  def teardown
    @mysql.close if @mysql
    FileUtils.rm_rf TMP_DIR
  end

  def test_buffer_is_null
    output = output_of 'first'
    stream 'first', output, 0
    assert_equal('', File.read(output))
  end

  def test_buffer_is_less_than_null
    assert_raise_message(/buffer size must be integer/, RuntimeError) do
      MysqlBlobStreaming.stream(
        @mysql,
        "SELECT data FROM blobs WHERE name = 'first'",
        -123
      ){ |chunk| raise "this should not happen!" }
    end
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
    assert_equal(input_size, @counter)

    @counter = 0
    stream('first', output, input_size)
    assert_equal(1, @counter)
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

  def test_stream_blob_almost_equal_to_buffer_but_less
    input, output = io_of 'first'
    stream('first', output, File.size(input) - 1)
    assert_equal(File.read(input), File.read(output))
  end

  def test_stream_blob_almost_equal_to_buffer_but_bigger
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

  def test_stream_with_utf8_name
    output = output_of 'hellö'
    stream 'hellö', output
    assert_equal('wörld', File.read(output))
  end

  def test_should_not_link_against_libruby_see_bug_12701
    running_on_mac = RUBY_PLATFORM.include?("darwin")
    dependency_checker_command = running_on_mac ? "otool -L" : "ldd"
    libraries = "#{LIB_DIR}/mysql_blob_streaming/mysql_blob_streaming*"
    dependencies = %x{#{dependency_checker_command} #{libraries} 2> /dev/null}

    assert !Dir.glob(libraries).empty?

    # sanity check to see if we got any sensible output from our dependency checker at all
    assert dependencies.include?(running_on_mac ? "libmysql" : "libc.so")

    assert !dependencies.include?("libruby")
  end

  # Helpers
  def stream(id, output, buffer_size = 65000)
    file = File.new(output, 'wb')
    escaped = @mysql.escape(id)
    MysqlBlobStreaming.stream(
        @mysql,
        "SELECT data FROM blobs WHERE name = '#{escaped}'",
        buffer_size
    ) do |chunk|
      @counter ||= 0
      @counter = @counter + 1
      file << chunk
    end
    file.close
  end

  def output_of(id)
    "#{TMP_DIR}/#{id}"
  end

  def io_of(id)
    ["#{FIX_DIR}/#{id}", output_of(id)]
  end
end
