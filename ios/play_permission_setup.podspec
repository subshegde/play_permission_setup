Pod::Spec.new do |s|
  s.name             = 'play_permission_setup'
  s.version          = '0.1.0'
  s.summary          = 'Reports the permissions the app declares in Info.plist.'
  s.description      = 'Native part of the play_permission_setup Flutter package.'
  s.homepage         = 'https://pub.dev/packages/play_permission_setup'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'play_permission_setup' => 'noreply@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '12.0'
  s.swift_version    = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
