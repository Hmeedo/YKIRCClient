Pod::Spec.new do |s|
  s.name         = 'YKIRCClient'
  s.version      = '1.0.0'
  s.summary      = 'IRC Client Library for iOS and OS X.'
  s.homepage     = 'https://github.com/yoshiki/YKIRCClient'
  s.license      = 'MIT'
  s.author       = 'Yoshiki Kurihara'
  s.source       = { :git => 'https://github.com/yoshiki/YKIRCClient.git' }
  s.source_files = 'YKIRCClient/*.{h,m}'
  s.requires_arc = true
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  s.dependency 'CocoaAsyncSocket'
end
