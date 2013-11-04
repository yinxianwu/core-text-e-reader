Pod::Spec.new do |s|
  s.name         = "CoreTextEBookReader"
  s.version      = '0.1.1'
  s.summary      = "E-reader framework using CoreText for rendering and display."

  s.description  = "E-reader framework using CoreText for rendering and display. More details to come."
  s.homepage     = "https://github.com/davidjed/core-text-e-reader"
  
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "David Jedeikin" => "djedei@gmail.com" }
 
  s.platform     = :ios, '6.1'
  s.requires_arc = true
  s.source       = { :git => "https://github.com/davidjed/core-text-e-reader.git", :tag => '0.1.1' }
  s.source_files = 'Classes', 'CoreTextEBookReader/**/*.{h,m}'
  s.resources = ["Images/*.png", "CoreTextEBookReader/*.xib"]
 end