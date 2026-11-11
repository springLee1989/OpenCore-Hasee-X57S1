# VoodooI2CHID 唤醒修复版编译说明

用 Xcode 编译 [VoodooI2CHID PR #78](https://github.com/VoodooI2C/VoodooI2CHID/pull/78)，提交 `338ad7f`（分支 `precision-touchpad-wake-fix`）。唤醒时先确认精度触控板的输入模式元素存在，再调用 `setDataValue`，避免空指针崩溃。

不要再用 `clang -mkernel` 手工编译。那一版能加载，但触摸板没有输入。kext 需要 Xcode 的内核扩展产品类型来生成正确的编译参数、预链接信息和链接方式。

可重复执行的脚本是 `build/build-voodooi2chid.sh`。

## 版本

| 组件 | 版本 |
| --- | --- |
| Xcode | 26.2（17C52） |
| 系统 | macOS 26.5.2（25F84），x86_64 |
| VoodooI2CHID | `338ad7f` Refine fix: logging cleanup |
| VoodooI2C 头文件 | 标签 `v2.9.1`（`e3ac3ed`），与 EFI 里的 `VoodooI2C.kext` 一致 |
| VoodooGPIO | `733dc80` |
| MacKernelSDK | `3f75008` |
| 配置 | Release，架构 x86_64，部署目标 10.11 |

## 目录

源码里的相对头文件路径按 VoodooI2C 仓库布局解析，`VoodooI2CHID` 必须放在 `VoodooI2C Satellites/` 下。工程里的 MacKernelSDK 路径是 `$(PROJECT_DIR)/../../MacKernelSDK`，对应 `build/i2c/MacKernelSDK`。

```text
build/i2c/                                      VoodooI2C v2.9.1
build/i2c/MacKernelSDK/                         acidanthera/MacKernelSDK
build/i2c/Dependencies/VoodooGPIO/              子模块
build/i2c/VoodooI2C Satellites/VoodooI2CHID/    PR #78 源码和 xcodeproj
build/xcode-derived/Build/Products/Release/     Xcode 产物
build/VoodooI2CHID.kext.original                替换前的原版备份
```

## 拉取源码

```bash
mkdir -p /Users/springmacbookpro/x57s1/build

git clone --depth 1 --branch v2.9.1 \
  https://github.com/VoodooI2C/VoodooI2C.git \
  /Users/springmacbookpro/x57s1/build/i2c

git -C /Users/springmacbookpro/x57s1/build/i2c \
  submodule update --init --depth 1 Dependencies/VoodooGPIO

git clone --depth 1 \
  https://github.com/acidanthera/MacKernelSDK.git \
  /Users/springmacbookpro/x57s1/build/i2c/MacKernelSDK

rm -rf "/Users/springmacbookpro/x57s1/build/i2c/VoodooI2C Satellites/VoodooI2CHID"
git clone --depth 1 --branch precision-touchpad-wake-fix \
  https://github.com/bliss95/VoodooI2CHID.git \
  "/Users/springmacbookpro/x57s1/build/i2c/VoodooI2C Satellites/VoodooI2CHID"
```

## 用 Xcode 编译

```bash
xcodebuild \
  -project "/Users/springmacbookpro/x57s1/build/i2c/VoodooI2C Satellites/VoodooI2CHID/VoodooI2CHID.xcodeproj" \
  -scheme VoodooI2CHID \
  -configuration Release \
  -derivedDataPath /Users/springmacbookpro/x57s1/build/xcode-derived \
  -arch x86_64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build
```

产物：

```text
build/xcode-derived/Build/Products/Release/VoodooI2CHID.kext
```

Xcode 26 会提示部署目标 10.11 低于当前支持范围，这是工程原设置，不影响生成 x86_64 kext。链接使用 `build/i2c/MacKernelSDK/Library/x86_64` 里的 `libkmod`，并带上 `-kext -lkmodc++ -lcc_kext`。

## 装进 EFI

工程关闭了签名，装进去之前做临时签名。原版备份在 `build/VoodooI2CHID.kext.original`，不要覆盖。

```bash
rm -rf /Users/springmacbookpro/x57s1/EFI/OC/Kexts/VoodooI2CHID.kext
cp -a /Users/springmacbookpro/x57s1/build/xcode-derived/Build/Products/Release/VoodooI2CHID.kext \
  /Users/springmacbookpro/x57s1/EFI/OC/Kexts/VoodooI2CHID.kext
codesign --force --sign - /Users/springmacbookpro/x57s1/EFI/OC/Kexts/VoodooI2CHID.kext
```

## 检查

```bash
file /Users/springmacbookpro/x57s1/EFI/OC/Kexts/VoodooI2CHID.kext/Contents/MacOS/VoodooI2CHID
# Mach-O 64-bit kext bundle x86_64

otool -h /Users/springmacbookpro/x57s1/EFI/OC/Kexts/VoodooI2CHID.kext/Contents/MacOS/VoodooI2CHID
# filetype 11 即 MH_KEXT_BUNDLE
```

未定义的 `VoodooI2C` 符号都能在现有的 `VoodooI2C.kext` 2.9.1 里找到。

## 恢复原版

```bash
cp -a /Users/springmacbookpro/x57s1/build/VoodooI2CHID.kext.original \
  /Users/springmacbookpro/x57s1/EFI/OC/Kexts/VoodooI2CHID.kext
```
