Pod::Spec.new do |s|
  s.name         = "Skeets"
  s.version      = "0.9.4"
  s.summary      = "Fetch, cache, and display images via HTTP in Swift."
  s.homepage     = "https://github.com/daltoniam/Skeets"
  s.license      = 'Apache License, Version 2.0'
  s.author       = {'Dalton Cherry' => 'http://daltoniam.com'}
  s.source       = { :git => 'https://github.com/daltoniam/Skeets.git',  :tag => "#{s.version}" }
  s.social_media_url = 'http://twitter.com/daltoniam'
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.source_files = '*.swift'
  s.requires_arc = 'true'
  s.dependency "SwiftHTTP", "~> 0.9.3"
end