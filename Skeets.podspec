Pod::Spec.new do |s|
  s.name         = "Skeets"
  s.version      = "0.9.1"
  s.summary      = "Fetch, cache, and display images via HTTP in Swift."
  s.homepage     = "https://github.com/daltoniam/Skeets"
  s.license      = 'Apache License, Version 2.0'
  s.author       = {'Dalton Cherry' => 'http://daltoniam.com'}
  s.source       = { :git => 'https://github.com/daltoniam/Skeets.git',  :tag => '0.9.1'}
  s.platform     = :ios, 8.0
  s.source_files = '*.{h,swift}'
  s.dependency   = 'SwiftHTTP'
end