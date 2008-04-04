MY_DIR = File.dirname(__FILE__)
FIX_DIR = "#{MY_DIR}/fixtures"
TMP_DIR = "#{MY_DIR}/tmp"

require 'rubygems'
require 'test/unit'
require 'fileutils'
require 'mysql'
require "#{MY_DIR}/fixtures"
require "#{MY_DIR}/../mysql_blob_streaming"

class MysqlBlobStreamingTest < Test::Unit::TestCase
	def setup
		Fixtures.insert

  	FileUtils.rm_rf TMP_DIR
  	FileUtils.mkdir TMP_DIR

		mysql_args = YAML::load_file("#{MY_DIR}/database.yml")
  	@mysql = Mysql.new(
  		'localhost',
  		mysql_args["username"], 
  		mysql_args["password"], 
  		mysql_args["database"] 
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

			def log_progress(pct)
				pct
			end
		end
	end

	def teardown
		@mysql.close if @mysql
		@stmt.close if @stmt

	 	FileUtils.rm_rf TMP_DIR
	end

  def test_buffer_is_null
  	output = "#{TMP_DIR}/buffer_null"

  	@stmt.file = File.new(output, 'w')
  	@stmt.execute 'first'
  	@stmt.stream 0

  	assert_equal('', File.read(output))
  end

  def test_buffer_is_less_than_null
  	output = "#{TMP_DIR}/buffer_less_null"

  	@stmt.file = File.new(output, 'w')
  	@stmt.execute 'first'

  	assert_raise RuntimeError do
  		@stmt.stream -123
  	end
  end

  def test_blob_data_is_null
  	output = "#{TMP_DIR}/data_null"

  	@stmt.file = File.new(output, 'w')
  	@stmt.execute 'empty'
  	@stmt.stream 65000

  	assert_equal('', File.read(output))
  end

	def test_buffer_has_specified_size
		output = "#{TMP_DIR}/known_size"
		input_size = File.size("#{FIX_DIR}/first")

		@stmt.file = File.new(output, 'w')
		@stmt.execute 'first'
		@stmt.stream 1
		@stmt.file.close

		assert_equal(input_size, @stmt.counter)

		@stmt.file = File.new(output, 'w')
		@stmt.execute 'first'
		@stmt.reset
		@stmt.stream input_size
		@stmt.file.close
		
		assert_equal(1, @stmt.counter)
	end

	def test_stream_blob_less_than_buffer
		output = "#{TMP_DIR}/less_than_buffer"
    input = "#{FIX_DIR}/first"

		@stmt.file = File.new(output, 'w')
		@stmt.execute 'first'
		@stmt.stream(File.size(input) * 100)
		@stmt.file.close

		assert_equal(File.read(input), File.read(output))
	end

	def test_stream_blob_bigger_than_buffer
		output = "#{TMP_DIR}/bigger_than_buffer"
    input = "#{FIX_DIR}/first"

		@stmt.file = File.new(output, 'w')
		@stmt.execute 'first'
		@stmt.stream(File.size(input) / 100)
		@stmt.file.close

		assert_equal(File.read(input), File.read(output))
	end

	def test_stream_blob_almoust_equal_to_buffer_but_less
		output = "#{TMP_DIR}/less_than_buffer"
    input = "#{FIX_DIR}/first"

		@stmt.file = File.new(output, 'w')
		@stmt.execute 'first'
		@stmt.stream(File.size(input) - 1)
		@stmt.file.close

		assert_equal(File.read(input), File.read(output))
	end
	
	def test_stream_blob_almoust_equal_to_buffer_but_bigger
		output = "#{TMP_DIR}/bigger_than_buffer"
    input = "#{FIX_DIR}/first"

		@stmt.file = File.new(output, 'w')
		@stmt.execute 'first'
		@stmt.stream(File.size(input) + 1)
		@stmt.file.close

		assert_equal(File.read(input), File.read(output))
	end

	def test_stream_same_blob_more_than_once
		output = "#{TMP_DIR}/many_times_the_same"
    input = "#{FIX_DIR}/first"

    10.times do
      @stmt.file = File.new(output, 'w')
      @stmt.execute 'first'
      @stmt.stream 65000
      @stmt.file.close
      assert_equal(File.read(input), File.read(output))
    end
	end

	def test_stream_different_blobs_serial
		output1 = "#{TMP_DIR}/many_times_the_different1"
    input1 = "#{FIX_DIR}/first"
		output2 = "#{TMP_DIR}/many_times_the_different2"
    input2 = "#{FIX_DIR}/second"

		10.times do
      @stmt.file = File.new(output1, 'w')
      @stmt.execute 'first'
      @stmt.stream 65000
      @stmt.file.close
      assert_equal(File.read(input1), File.read(output1))

      @stmt.file = File.new(output2, 'w')
      @stmt.execute 'second'
      @stmt.stream 65000
      @stmt.file.close
      assert_equal(File.read(input2), File.read(output2))
		end
	end

  def test_stream_really_big_blobs
    assert true
  end

  def test_stream_really_tiny_blobs
		output = "#{TMP_DIR}/very_small"
    input = "#{FIX_DIR}/small"

		@stmt.file = File.new(output, 'w')
		@stmt.execute 'small'
		@stmt.stream 65000
		@stmt.file.close
		assert_equal(File.read(input), File.read(output))
  end

	def test_logging
		assert true
	end
end
