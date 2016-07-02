
Pod::Spec.new do |s|

  s.name             = 'YJSafeKVO'
  s.version          = '2.0.0'
  s.summary          = 'A simple and safe key value observing pattern for Cocoa programming.'
  s.description      = <<-DESC
                       Using YJSafeKVO is a simple, better way for implementing key value observing.
                       DESC

  s.homepage         = 'https://github.com/huang-kun/YJSafeKVO'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'huang-kun' => 'jack-huang-developer@foxmail.com' }
  s.source           = { :git => 'https://github.com/huang-kun/YJSafeKVO.git', :tag => s.version.to_s }
  s.social_media_url = 'http://weibo.com/u/5736413097'

  s.requires_arc = true
  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'

  s.source_files = 'YJSafeKVO/Classes/**/*'
  s.public_header_files = 'YJSafeKVO/Classes/**/*.h'

end
