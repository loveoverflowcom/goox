#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint goox_terminal.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'goox_terminal'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for terminal emulation with PTY support using Rust FFI.'
  s.description      = <<-DESC
A Flutter plugin that provides terminal emulation capabilities with pseudo-terminal (PTY) support.
Built with Rust for high performance and cross-platform compatibility.
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

  # Cargokit integration for Rust FFI
  s.script_phase = {
    :name => 'Build Rust library',
    :script => 'sh "$PODS_TARGET_SRCROOT/../cargokit/build_pod.sh" ../rust goox_terminal',
    :execution_position => :before_compile,
    :input_files => ['${BUILT_PRODUCTS_DIR}/cargokit_phony'],
    :output_files => ["${BUILT_PRODUCTS_DIR}/goox_terminal.framework"],
  }
end
