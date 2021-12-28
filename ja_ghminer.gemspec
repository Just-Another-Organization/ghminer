Gem::Specification.new do |spec|
  spec.name = 'ja_ghminer'
  spec.version = '0.1-alpha'
  spec.authors = ['ZappaBoy']
  spec.email = ['federico_zappone@hotmail.it']

  spec.summary = 'Just Another GitHub Miner'
  spec.description = 'Just Another GitHub Miner'
  spec.homepage = 'https://github.com/ZappaBoy/JA-GHMiner'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/ZappaBoy/JA-GHMiner.git'
  spec.files = Dir.glob('lib/**/*.rb')
  spec.license = 'AGPL-3.0'
end
