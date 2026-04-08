#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint goox_terminal.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'goox_terminal'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for terminal emulation with PTY support.'
  s.description      = <<-DESC
A Flutter plugin that provides terminal emulation capabilities with pseudo-terminal (PTY) support.
Built with pure Dart using xterm and flutter_pty for cross-platform compatibility.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
