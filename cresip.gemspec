# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
    s.name        = "crescip"
    s.version     = '0.9.0'
    s.authors     = ["Stephen von Takach"]
    s.email       = ["steve@cotag.me"]
    s.licenses    = ["MIT"]
    s.homepage    = "https://github.com/advancedcontrol/ruby-crescip"
    s.summary     = "Crestron IP protocol on Ruby"
    s.description = <<-EOF
        Constructs and parses Crestron IP packets allowing you to communicate with Crestron devices without a controller
    EOF


    s.add_dependency 'bindata', '~> 2.3'

    s.add_development_dependency 'rspec', '~> 3.5'
    s.add_development_dependency 'yard',  '~> 0'
    s.add_development_dependency 'rake',  '~> 11'


    s.files = Dir["{lib}/**/*"] + %w(cresip.gemspec README.md)
    s.test_files = Dir["spec/**/*"]
    s.extra_rdoc_files = ["README.md"]

    s.require_paths = ["lib"]
end
