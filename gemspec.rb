SPEC = Gem::Specification.new do |spec|

  # Folgende Zeile bitte löschen, wenn sie nicht mehr aktuell ist!
  puts "\n\33[33mFIXME: Spezifikation ist noch nicht vollständig!\e[0m\n"

  spec.name = 'mysql_blob_streaming'
  spec.version = '1.0.0'
  spec.summary = 'A blob streaming extension for native Ruby-MySQL adapter'
  spec.author = 'Infopark AG'
  spec.homepage = 'http://www.infopark.com'
  spec.email = 'support@infopark.com'

  spec.add_dependency('mysql', '>=2.7')
  spec.required_ruby_version = '>=1.8.5'

  spec.files = %w|mysql_blob_streaming.so README|
  spec.require_path = '.'

  spec.has_rdoc = true
  spec.extra_rdoc_files = ['README']
  spec.rdoc_options = ['--main', 'README']
end
