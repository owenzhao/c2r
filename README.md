# c2r 
## Calendar to Reminder

c2r监控你指定的日历，当你添加新任务时，它会在任务结束的时刻，提前几分钟发出提醒。默认时间是提前3分钟。

如果你开启了同步，提醒也会同步到你的其它设备。

## 下载
预先编译好的版本，支持10.10以上macOS。</br>

### 最新
[1.1 170420](https://github.com/owenzhao/c2r/raw/master/app/1.1.170420/c2r%201.1.170420.dmg)

### 旧版
[1.0 170419](https://github.com/owenzhao/c2r/raw/master/app/1.0.170419/c2r%201.0.170419.dmg)

## 编译方法：
Xcode 8.3.2 (8E2002)

1. 使用Cocoapod下载第三方的库（RxSwift, RxCocoa, RealmSwift)
2. 打开文件夹的`c2r.xcworkspace`文件

### 命令版本:

1. cd c2r
2. pod install
3. open c2r.xcworkspace

## 新变化
### 版本1.1.170420
* 修正Windows标题为c2r，之前为Window
* 程序代码优化