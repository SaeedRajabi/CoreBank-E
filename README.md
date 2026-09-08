# BankCore — Professional Banking System (ADO.NET + SQL Server + WinForms)

<p align="center">
  <img src="Bank.UI/Assets/Icons/ArkaSoftware-Image.png" alt="ArkaSoftware" width="120" />
</p>

<p align="center">
  <strong>A production-grade, educational desktop banking platform built with Clean Architecture</strong><br/>
  .NET 10 • Windows Forms • ADO.NET • SQL Server • DDD
</p>

<p align="center">
  <a href="https://arkasoftware.ir"><img src="https://img.shields.io/badge/Website-arkasoftware.ir-2563eb?style=flat-square" alt="Website" /></a>
  <img src="https://img.shields.io/badge/.NET-10.0-512BD4?style=flat-square&logo=dotnet" alt=".NET 10" />
  <img src="https://img.shields.io/badge/Platform-Windows-0078D6?style=flat-square&logo=windows" alt="Windows" />
  <img src="https://img.shields.io/badge/Database-SQL%20Server%202019+-CC2927?style=flat-square&logo=microsoftsqlserver" alt="SQL Server" />
  <img src="https://img.shields.io/badge/Architecture-Clean%20DDD-0ea5e9?style=flat-square" alt="Clean Architecture" />
  <img src="https://img.shields.io/badge/License-Proprietary-orange?style=flat-square" alt="License" />
</p>

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Screenshots](#screenshots)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Database Setup](#database-setup)
- [Configuration](#configuration)
- [Demo Mode](#demo-mode)
- [Smoke Tests](#smoke-tests)
- [Database Documentation](#database-documentation)
- [Security](#security)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [About the Developer](#about-the-developer)
- [Contact & Support](#contact--support)
- [License](#license)

---

## Overview

**BankCore** is a desktop banking core system designed for both **production use** and **academic training**. It demonstrates enterprise software engineering principles — Clean Architecture, Domain-Driven Design (DDD), Role-Based Access Control (RBAC), double-entry bookkeeping, and comprehensive SQL Server programming — wrapped in a polished, RTL Persian user interface.

Originally developed as an educational platform to teach database concepts (stored procedures, functions, views, triggers, transactions, indexing, window functions, and more), the system has evolved into a full-featured banking application with authentication, granular permissions, audit logging, and a modern WinForms UI powered by the custom **Vazir** Persian font.

> **Dual-Mode Operation:** Runs against a real SQL Server instance when `BANK_SQL_CONNECTION` is configured, or seamlessly falls back to an in-memory demo mode for offline development and UI preview.
