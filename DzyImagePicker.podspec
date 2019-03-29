Pod::Spec.new do |s|

 s.name         = 'DzyImagePicker'

 s.version      = '1.0.0'

 s.summary      = 'image picker'

 s.description  = <<-DESC
                  仿微信制作的图片编辑控件，欢迎各位大佬提 pr
                   DESC

 s.homepage     = 'https://github.com/dzyding/ImagePicker'

 s.license      = { :type => 'MIT', :file => 'LICENSE' }

 s.author       = '灰s'

 s.platform     = :ios, '9.0'

 s.source        = { :git => 'https://github.com/dzyding/ImagePicker.git', :tag => '1.0.0' }

 s.source_files  = 'Source/*.swift'

 s.resources     = 'Images/*.png'  

 s.swift_version = '4.2'

 s.dependency 'SnapKit', '~> 4.2.0'

end
