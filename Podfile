# Uncomment the next line to define a global platform for your project
#platform :ios, '9.0'

source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'

platform :osx, '10.13'
inhibit_all_warnings!

target 'c2r' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for c2r
  pod 'RxSwift',    '~> 4.0'
  pod 'RxCocoa',    '~> 4.0'
  pod 'RealmSwift'
  #pod 'RxRealm'

  target 'c2rTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'RxBlocking', '~> 4.0'
    pod 'RxTest',     '~> 4.0'
    
  end

  target 'c2rUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
