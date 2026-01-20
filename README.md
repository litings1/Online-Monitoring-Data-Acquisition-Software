# 在线监测数据采集软件

> 面向环境在线监测系统的数据采集、设备通信与协议解析软件  
> 支持多仪器接入、统一协议抽象、实时数据采集与存储

---

## 📌 项目简介

本项目用于 **环境在线监测系统**，实现对多种现场仪器的数据采集、协议解析与统一管理。

特点：
- 🧠 软件 / 仪器 / 协议 解耦设计
- 🔌 支持多种通信方式（TCP / 串口 / Modbus / 自定义协议）
- 📊 实时数据采集、缓存与上报
- 🛠 适用于 VOC、气体分析、离子色谱等在线仪器

---

## 🧩 系统总体架构

<p align="center">
  < img src="/images/ScreenShot_main.png" width="750">
</p >

说明：
- **采集服务**：负责设备通信与数据采集
- **协议层**：解析不同厂商、不同格式的数据
- **数据层**：统一结构化存储
- **上层应用**：显示、报警、上传平台

---

## 🖥 软件展示

### 主界面
<p align="center">
  < img src="images/ui_main.png" width="700">
</p >

### 数据监控
<p align="center">
  < img src="images/ui_realtime.png" width="700">
</p >

---

## 🔌 支持的仪器（示例）

<p align="center">
  < img src="images/device_1.jpg" width="280">
  < img src="images/device_2.jpg" width="280">
</p >

- NDIR 气体分析仪
- VOC 在线监测设备
- 离子色谱（IC）
- 自定义采集模块（ESP32 / MCU）

---

## 📡 通信方式与协议

### 通信方式
- TCP / UDP
- RS232 / RS485
- Modbus TCP / RTU
- 自定义二进制协议

### 协议设计
<p align="center">
  < img src="images/protocol.png" width="650">
</p >

- 协议抽象层（Protocol Adapter）
- 支持校验、帧解析、重组
- 易扩展新仪器

---
