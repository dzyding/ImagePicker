Pod::Spec.new do |s|

 s.name         = 'DzyImagePicker'

 s.version      = '1.1.7'

 s.summary      = 'image picker'

 s.description  = <<-DESC
                  仿微信制作的图片编辑控件，欢迎各位大佬提 pr
                   DESC

 s.homepage     = 'https://github.com/dzyding/ImagePicker'

 s.license      = { :type => 'MIT', :file => 'LICENSE' }

 s.author       = '灰s'

 s.platform     = :ios, '10.0'

 s.source       = { :git => 'https://github.com/dzyding/ImagePicker.git', :tag => '1.1.3' }

 s.source_files  = 'Source/*.swift'

 s.resources     = 'Resources/*.*'  

 s.swift_version = '5.0'

 s.dependency 'SnapKit', '~> 5.0.0'

end
