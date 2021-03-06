require './lib/infoboxer/version'

Gem::Specification.new do |s|
  s.name     = 'infoboxer'
  s.version  = Infoboxer::VERSION
  s.authors  = ['Victor Shepelev']
  s.email    = 'zverok.offline@gmail.com'
  s.homepage = 'https://github.com/zverok/infoboxer'

  s.summary = 'MediaWiki client and parser, targeting information extraction.'
  s.description = <<-EOF
    Infoboxer is library targeting use of Wikipedia (or any other
    MediaWiki-based wiki) as a rich powerful data source.
  EOF
  s.licenses = ['MIT']

  s.files = `git ls-files`.split($RS).reject do |file|
    file =~ /^(?:
    spec\/.*
    |Gemfile
    |Rakefile
    |\.rspec
    |\.gitignore
    |\.rubocop.yml
    |\.travis.yml
    )$/x
  end
  s.require_paths = ["lib"]

  s.add_dependency 'htmlentities'
  s.add_dependency 'procme'
  s.add_dependency 'rest-client'
  s.add_dependency 'addressable'
  s.add_dependency 'terminal-table'
  s.add_dependency 'backports'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'rspec-its', '~> 1'
  s.add_development_dependency 'ruby-prof'
  s.add_development_dependency 'vcr'
  s.add_development_dependency 'webmock'
end
