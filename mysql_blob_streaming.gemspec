SPEC = Gem::Specification.new do |spec|
  spec.name = 'mysql_blob_streaming'
  spec.version = "1.1.3"
  spec.summary = 'A blob streaming extension for the native Ruby-MySQL adapter'
  spec.author = 'Infopark AG'
  spec.homepage = 'http://www.infopark.de/'
  spec.email = 'info@infopark.de'
  spec.requirements << 'Infopark Rails Connector (RC)'
  spec.description = <<-EOF
    This GEM is required by the Infopark Rails Connector (RC) when using MySQL.
  EOF

  spec.add_dependency('mysql', '>=2.7')
  spec.required_ruby_version = '>=1.8.7'

  spec.files = Dir["lib/**/*.rb", "ext/**/*.{c,h,rb}", "README.markdown"]
  spec.extensions = ['ext/mysql_blob_streaming/extconf.rb']

  spec.has_rdoc = true
  spec.extra_rdoc_files = Dir['README*']
  spec.rdoc_options = ['--main', Dir['README*'].first]
end
