Pod::Spec.new do |s|
 s.name = 'AAPlayer'
 s.version = '1.0.0'
 s.license = { :type => "MIT", :file => "LICENSE.md" }
 s.summary = 'Customize Video Player base on AVPlayer'
 s.homepage = 'https://github.com/Alan881/AAPlayer'
 s.authors = { 'Alan' => 'nakama74@gmail.com' }
 s.source = { :git => 'https://github.com/Alan881/AAPlayer.git', :tag => s.version }
 s.source_files = 'Sources/*.swift'
 s.requires_arc = true
 s.ios.deployment_target = '8.0'
end
