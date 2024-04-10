# 
<p align="center">
<img src="./Pixboard/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" width="200" height="200" />
<h1 align="center">Pixboard</h1>
<h3 align="center">运行在 Mac 桌面上的复古显示设备模拟器<br></h3> 
</p>

## 运行截图
<p align="center">
<img src="./img/preview.png" width="712"/> 
</p>

## 安装与使用
### 系统版本要求:
- macOS 11.0 及更高版本  

### 安装:
可[点此前往](../../releases/latest)下载最新版安装文件. 或使用homebrew安装:  

```bash
brew install lihaoyun6/tap/pixboard
```

### 使用:
- Pixboard 启动后会显示主窗口, 可以将任意图片拖拽进去, 或右键单击打开文件.  

- Pixboard 支持使用 Schema URL 接口来修改显示内容或面板设置等 [[URL格式说明](#url)]  
- 右键单击主窗口可选择新建多个显示面板, 以显示不同内容 (但 API 只能修改主面板) 
- Pixboard 还支持 `HDR` 功能, 在具备 `HDR` 能力的显示器上开启可让拟真度更上一层 

## 常见问题
**1. Pixboard 支持哪些图片格式? 支持 gif 动图吗?**  
> Pixboard 使用系统 API 对图像进行预读取, 支持几乎所有"预览"程序能够打开查看的图片格式, 包括 gif 动图.  

**2. 如何移动或切换全屏显示 Pixboard 面板?**  
> 鼠标直接按住拖拽即可移动面板, 双击面板内任意位置切换全屏 (或在`右键` > `面板操作...`菜单内切换)   

<h2 id="url">Schema URL 格式说明</h2>
Pixboard 的 URL 前缀是 `pixboard://`, 支持的指令和参数格式如下:  

**mode**  
> mode 命令用于切换面板显示模式, 支持如下参数:  
> `led`, `led_circle`, `crt`, `crt_green`, `crt_amber`, `crt_mono`, `lcd`, `lcd_invert`, `vfd`, `vfd_yellow`  
> 使用样例: `pixboard://mode?VFD`  

**resize**
> resize 命令用于设置面板对图像的缩放算法, 可选参数有:  `nearest`, `normal`  
> 其中 `nearest` 表示锐利缩放, `normal` 表示柔和缩放
> 使用样例: `pixboard://resize?normal`  

**rotate**  
> rotate 命令用于设置图像旋转角度, 可选参数有: `0`, `90`, `180`, `270`  
> 使用样例: `pixboard://rotate?90`  

**ontop**
> ontop 命令用于切换窗口置顶状态, 参数可以设为 `1` 或 `0`. 设为 `1` 代表开启置顶, `0` 代表取消置顶  
> 使用样例: `pixboard://ontop?0`

**hdr**
> 用于开关 HDR 效果, 参数可以设为 `1` 或 `0`. 设为 `1` 代表开启 HDR, `0` 代表关闭 HDR  
> 使用样例: `pixboard://hdr?1`

**invert**
> invert 命令用于切换图像反色效果, 参数可以设为 `1` 或 `0`. 设为 `1` 代表显示反色图像, `0` 代表显示原始图像  
> 使用样例: `pixboard://invert?0`

**image_file**
> image_file 命令用于指定要显示的图像路径, 参数值为图像路径.  
> 使用样例: `pixboard://image_file?/path/to/image.jpg`

**image_data**
> image_file 命令用于指定要显示的图像数据, 参数值为 base64 格式的图像数据.  
> 使用样例: `pixboard://image_data?iVBORw0KGgoAAAANSUhEUgAAAAIAAAACAQMAAABIeJ9nAAAABlBMVEX///8AAABVwtN+AAAADElEQVQI12NoYHAAAAHEAMFJRSpJAAAAAElFTkSuQmCC`

**clear_cache**
> clear_cache 命令用于立即清空 Pixboard 的图像缓存, 此命令无附加参数, 清空缓存不会影响当前显示.  
> 使用样例: `pixboard://clear_cache`

## 致谢
[SDWebImage](https://github.com/SDWebImage/SDWebImage) @SDWebImage  
[SDWebImageSwiftUI](https://github.com/SDWebImage/SDWebImageSwiftUI) @SDWebImage  
[FileHash](https://github.com/CrazyFanFan/FileHash) @CrazyFanFan  

## 赞助
<img src="./img/donate.png" width="352"/>
