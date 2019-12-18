require 'date'
require File.expand_path('../lib/cici/version', __FILE__)

Gem::Specification.new do |s|
  s.name          = 'cici'
  s.version       = CICI::Version.get
  s.date          = Date.today.to_s
  s.summary       = 'Confidential Information for Continuous Integration (CICI)'
  s.description   = 'When environment variables are not enough and you need to store secrets within files, cici is your friend. Store secret files in your source code repository with ease. Can be used without a CI server, but tool is primarily designed for your CI server to decrypt these secret files for deployment.'
  s.authors       = ['Levi Bostian']
  s.email         = 'levi.bostian@gmail.com'
  s.files         = Dir.glob('{bin,lib}/**/*') + %w[LICENSE README.md CHANGELOG.md]
  s.bindir        = "bin"
  s.executables   = ["cici"]
  s.require_paths = ["lib"]
  s.homepage      = 'https://github.com/levibostian/cici'
  s.license       = 'MIT'
  s.add_runtime_dependency 'colorize', '~> 0.8', '>= 0.8.1'
  s.add_development_dependency 'rubocop', '~> 0.58', '>= 0.58.2'
  s.add_development_dependency 'rake', '~> 12.3', '>= 12.3.1'
  s.add_development_dependency 'rspec', '~> 3.8', '>= 3.8.0'
  s.add_development_dependency 'rspec_junit_formatter', '~> 0.4', '>= 0.4.1'
end