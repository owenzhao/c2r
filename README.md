# c2r 
## Calendar to Reminder

c2r监控你指定的日历，当你添加新任务时，它会在任务结束的时刻，提前几分钟发出提醒。默认时间是提前3分钟。

如果你开启了同步，提醒也会同步到你的其它设备。

## 下载
预先编译好的版本，支持10.10以上macOS。</br>

### 最新
[1.5 170421](https://github.com/owenzhao/c2r/raw/master/app/1.5.170421/c2r%201.5.170421.dmg)

### 旧版
[1.1 170420](https://github.com/owenzhao/c2r/raw/master/app/1.1.170420/c2r%201.1.170420.dmg)</br>
[1.0 170419](https://github.com/owenzhao/c2r/raw/master/app/1.0.170419/c2r%201.0.170419.dmg)

## 安装方法看这里

[视频地址](http://weibo.com/1711715275/EFghh1dlV?type=comment)

## 更新
直接覆盖即可

## 编译方法：
Xcode 8.3.2 (8E2002)

1. 使用Cocoapod下载第三方的库（RxSwift, RxCocoa, RealmSwift)
2. 打开文件夹的`c2r.xcworkspace`文件

### 命令版本:

1. cd c2r
2. pod install
3. open c2r.xcworkspace

## 新变化
### 版本1.5.170421
* 新功能：当日期改变时，主动查询日历，以保证提醒为最新。
* 新功能：当日期改变时，会主动清理程序内部数据库中无用的数据，减小磁盘占用。
* 修正：修复了一个bug。之前如果一个任务完成了，重新运行程序，会再次添加一个过期的新提醒。这个问题目前已修复。
* 改进：当用户关闭程序窗口时，程序会自动退出。
* 改进：提高了程序的启动速度和运行速度。

### 版本1.1.170420
* 修正Windows标题为c2r，之前为Window
* 程序代码优化

### 版本1.0.170419
* 初版发布