SPEC = Gem::Specification.new do |spec|
  spec.name = 'mysql_blob_streaming'
  spec.version = "2.0.0"
  spec.summary = 'A blob streaming extension for the native Ruby-MySQL2 adapter'
  spec.author = 'Infopark AG'
  spec.homepage = 'http://www.infopark.de/'
  spec.email = 'info@infopark.de'
  spec.requirements << 'Infopark Rails Connector (RC)'
  spec.description = <<-EOF
    This GEM is required by the Infopark Rails Connector (RC) when using MySQL.
  EOF

  spec.add_dependency('mysql2', '0.3.11')
  spec.required_ruby_version = '>=1.8.7'

  spec.files = Dir["lib/**/*.rb", "ext/**/*.{c,h,rb}", "README.markdown"]
  spec.extensions = ['ext/mysql_blob_streaming/extconf.rb']

  spec.has_rdoc = true
  spec.extra_rdoc_files = Dir['README*']
  spec.rdoc_options = ['--main', Dir['README*'].first]
end
