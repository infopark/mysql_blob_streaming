SPEC = Gem::Specification.new do |spec|
	puts 
  spec.name = 'mysql_blob_streaming'
  spec.version = File.read('./version').chop
  spec.summary = 'A blob streaming extension for the native Ruby-MySQL adapter'
  spec.author = 'Infopark AG'
  spec.homepage = 'http://www.infopark.de/'
  spec.email = 'info@infopark.de'
  spec.requirements << 'Infopark Rails Connector (RC)'
  spec.description = <<-EOF
    This GEM is required when using the Infopark Rails Connector (RC) in
    conjunction with MySQL. It has to be installed on all servers on
    which the RC is running.

    This GEM may only be used in conjunction with a valid license of the
    Infopark Rails Connector (RC).

    (c) 2008 Infopark AG. All rights reserved.
  EOF

  spec.add_dependency('mysql', '>=2.7')
  spec.required_ruby_version = '>=1.8.6'

	os_extension_mapping = {
		'linux' => 'so', 
		'darwin' => 'bundle'
	}
	spec.files = ["mysql_blob_streaming.#{os_extension_mapping[ENV['ostype']]}", 'README']

  spec.require_path = '.'

  spec.has_rdoc = true
  spec.extra_rdoc_files = ['README']
  spec.rdoc_options = ['--main', 'README']
end
