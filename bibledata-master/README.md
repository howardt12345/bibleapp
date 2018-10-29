* [English](#english)
  * [Install Offline Bible Reader](#install-offline-bible-reader)
  * [What's "Bible Data"](#whats-bible-data)
  * [Install "Bible Data" Manually](#install-bible-data-manually)
  * [Request Other Version](#request-other-version)
* [中文](#中文)
  * [安装离线圣经阅读器](#安装离线圣经阅读器)
  * [什么是圣经数据](#什么是圣经数据)
  * [手动安装圣经数据](#手动安装圣经数据)
  * [需要其它版本](#需要其它版本)

# English

## Install Offline Bible Reader

Please get Offline Bible Reader from Google Play Store <https://play.google.com/store/apps/details?id=me.piebridge.bible>, or <https://github.com/liudongmiao/bible/releases>.

## What's "Bible Data"

As there are little bible versions in public domain, so I seperate the Offline Bible Reader and the Bible Data.

The Offline Bible Reader, is distributed in free license, you can get the source code from <http://github.com/liudongmiao/bible>. However, I have no right to distribute any bible version not in public domain.

Furthermore, the Offline Bible Reader, update more frequently than the Bible Data. So its unnecessary to pack a much bigger bible data with a little reader.

## Install "Bible Data" Manually

**NOTE: ONLY FOR PERSONAL USAGE.**

* Download the `bibledata-<language>-<version>.zip` from <http://github.com/liudongmiao/bibledata>.
* (New Way) Put the `bibledata-<language>-<version>.zip` into `<SDCARD>` directory or `<SDCARD>/Download` (android browser's default download directory), and open the bible, and be patient, it will show when it's installed.
  * Require bible v0.9.18+
* (Old Way) Uncompress the `bibledata-<language>-<version>.zip`, and put the sqlite3 file `<version>.sqlite3` to `<SDCARD>/Android/data/me.piebridge.bible/files` directory.

## Request Other Version

Create an issue from <https://github.com/liudongmiao/bibledata/issues/new>, offer these things:

1. The version name and the version link. Currently these versions should be supported:
   * <http://bibles.org/versions>
   * <http://www.biblegateway.com/versions>

1. If the version is not in [public domain](http://en.wikipedia.org/wiki/Public_domain), ask the permission from the copyright holder.

# 中文

## 安装离线圣经阅读器

请从谷歌电子市场<https://play.google.com/store/apps/details?id=me.piebridge.bible>或者<https://github.com/liudongmiao/bible/releases>获取离线圣经阅读器。

## 什么是圣经数据

只有少数圣经版本在公有领域，所以我决定分开离线圣经阅读器与圣经数据。

离线圣经阅读器使用自由协议发布，您可以从<http://github.com/liudongmiao/bible>获取源代码。然而，我没有任何权限发布不在公有领域的圣经版本。

此外，离线圣经阅读器经常更新。所以，没有必要把一个非常大的圣经数据与一个非常小的阅读器一起打包。

## 手动安装圣经数据

**注意：仅供个人使用。**

* 请从<http://github.com/liudongmiao/bibledata>下载`bibledata-<语言>-<版本>.zip`。
* (新方法) 把`bibledata-<语言>-<版本>.zip`放入`<SDCARD>`根目录或者`<SDCARD>/Download`(浏览器下载默认目录)，然后打开圣经程序，等待一定时间，它就会显示。
  * 要求0.9.18以上版本
* (老方法) 解压`bibledata-<语言>-<版本>.zip`，把sqlite3文件`<版本>.sqlite3`放入`<SDCARD>/Android/data/me.piebridge.bible/files/`目录。

## 需要其它版本

请从<https://github.com/liudongmiao/bibledata/issues/new>创建一个问题，提供以下内容：

1. 版本名称及链接。当前支持以下版本：
   * <http://bibles.org/versions>
   * <http://www.biblegateway.com/versions>

1. 如果版本不在[公有领域](http://zh.wikipedia.org/wiki/%E5%85%AC%E6%9C%89%E9%A2%86%E5%9F%9F)，请联系版本所有者获取许可。
