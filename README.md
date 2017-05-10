# c2r 
## Calendar to Reminder

c2r监控你指定的日历，当你添加新任务时，它会在任务结束的时刻，提前几分钟发出提醒。默认时间是提前3分钟。

如果你开启了同步，提醒也会同步到你的其它设备。

## 下载
预先编译好的版本，支持10.10以上macOS。</br>

### 最新
[1.6.2 170512](https://github.com/owenzhao/c2r/raw/master/app/1.6.2.170512/c2r%201.6.2%20170512.dmg)

### 旧版
[1.5.5 170426](https://github.com/owenzhao/c2r/raw/master/app/1.5.5%20170426/c2r%201.5.5%20170426.dmg)
[1.5.4 170425](https://github.com/owenzhao/c2r/raw/master/app/1.5.4%20170425/c2r%201.5.4%20170425.dmg)
[1.5.3 170424](https://github.com/owenzhao/c2r/raw/master/app/1.5.3%20170424/c2r%201.5.3%20170424.dmg)</br>
[1.5.2 170423](https://github.com/owenzhao/c2r/raw/master/app/1.5.2%20170423/c2r%201.5.2%20170423.dmg)</br>
[1.5 170421](https://github.com/owenzhao/c2r/raw/master/app/1.5.170421/c2r%201.5.170421.dmg)</br>
[1.1 170420](https://github.com/owenzhao/c2r/raw/master/app/1.1.170420/c2r%201.1.170420.dmg)</br>
[1.0 170419](https://github.com/owenzhao/c2r/raw/master/app/1.0.170419/c2r%201.0.170419.dmg)

## 安装与使用

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
### 版本 1.6.2 170512
* 新增：Dock栏图标状态，c2r监控时，会显示蓝色条
* 新增：自动恢复运行状态。在监控状态下关闭c2r，或重启、关闭计算机，或注销用户时，再次打开c2r，c2r会自动恢复监控。
* 上两条相结合，用户可以从Dock栏的图标直接了解c2r当前的监控状态
* c2r常驻Dock栏，而非菜单栏，因为相对于Dock，菜单栏的图标太过拥挤了。
* 说明：如果之前监控的日历被删除了，或写入的提醒列表被删除了，c2r将不会自动继续监控。
* 修正：之前如果监控的日历项目修改了结束时间，并且结束时间早于当前时间，原有的提醒项没有正确的更新或删除。新版修复了这个问题。

### 版本 1.5.5 170426
* 改进：性能改进

### 版本 1.5.4 170425
* 修正：解决了一个问题。被监控的行程改变所在的日历时，该行程还会被监控。本版会删除对该行程的监控，并删除对应的提醒。

### 版本 1.5.3 170424
* 修正：解决了程序非预期退出的问题。

### 版本 1.5.2 170423
* 改动：上一版会删除已经完成的提醒事项。这一版，恢复提醒事项的默认行为，完成的提醒不再删除。
* 改进：关闭窗口时能够正确关闭程序，避免误判。

### 版本1.5 170421
* 新功能：当日期改变时，主动查询日历，以保证提醒为最新。
* 新功能：当日期改变时，会主动清理程序内部数据库中无用的数据，减小磁盘占用。
* 修正：修复了一个bug。之前如果一个任务完成了，重新运行程序，会再次添加一个过期的新提醒。这个问题目前已修复。
* 改进：当用户关闭程序窗口时，程序会自动退出。
* 改进：提高了程序的启动速度和运行速度。

### 版本1.1 170420
* 修正Windows标题为c2r，之前为Window
* 程序代码优化

### 版本1.0 170419
* 初版发布

