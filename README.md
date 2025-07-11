# 🏢 Vertic App - Digital Sports Facility Management

**A modern, cross-platform Flutter app that serves as a secure and user-friendly digital access point for sports facilities - especially bouldering halls.**

![Vertic](https://img.shields.io/badge/Flutter-Cross--Platform-blue?logo=flutter)
![Serverpod](https://img.shields.io/badge/Backend-Serverpod-green?logo=dart)
![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-blue?logo=postgresql)
![Status](https://img.shields.io/badge/Status-Production--Ready-success)

---

## 🎯 **Project Overview**

Vertic is a comprehensive digital management system for sports facilities, featuring:

- **🎫 Digital Ticket System** - Purchase, validate, and manage access tickets
- **👥 User Management** - Complete customer and staff administration  
- **🏢 Facility Management** - Multi-location support with hierarchical structure
- **🔐 RBAC Security** - Role-based access control with 33+ permissions
- **📊 Analytics & Reports** - Business insights and operational data
- **🖨️ Hardware Integration** - Printer support for physical tickets

---

## 🏗️ **Architecture**

### **Frontend Apps**
- **Staff App** (`vertic_project/vertic_staff_app/`) - Administrative interface
- **Client App** (`vertic_project/vertic_client_app/`) - Customer-facing app

### **Backend Services**  
- **Serverpod Server** (`vertic_server/`) - API & business logic
- **PostgreSQL Database** - Data persistence with migrations
- **Unified Authentication** - Single login system for both apps

### **Key Technologies**
- **Flutter 3.7+** - Cross-platform mobile/desktop development
- **Serverpod 2.8** - Type-safe Dart backend framework
- **PostgreSQL** - Production-grade database
- **bcrypt** - Secure password hashing
- **JWT Tokens** - Session management

---

## 🚀 **Getting Started**

### **Prerequisites**
- Flutter SDK 3.7+
- Dart SDK 3.7+  
- PostgreSQL 13+
- DBeaver/pgAdmin (recommended)

### **Quick Setup**

1. **Clone Repository**
   ```bash
   git clone https://github.com/LeonStadler/vertic_app.git
   cd vertic_app
   ```

2. **Database Setup**
   ```bash
   # Run PostgreSQL and create 'test_db' database
   # Execute SQL scripts in order:
   # 1. vertic/SQL/01_CLEAN_SETUP.sql
   # 2. vertic/SQL/02_CREATE_SUPERUSER.sql
   ```

3. **Start Backend**
   ```bash
   cd vertic/vertic_server/vertic_server_server
   dart pub get
   dart run bin/main.dart --apply-migrations
   ```

4. **Start Staff App**
   ```bash
   cd vertic/vertic_project/vertic_staff_app  
   flutter pub get
   flutter run
   ```

5. **Login**
   - **Username**: `superuser`
   - **Password**: `super123`

---

## 📋 **Features**

### **🎫 Ticket Management**
- Digital ticket sales and validation
- Multiple ticket types and pricing tiers
- Real-time availability tracking
- Integration with payment systems

### **👥 User Administration**
- Customer profile management
- Staff hierarchy and permissions
- Role-based access control (RBAC)
- Session management and security

### **🏢 Multi-Facility Support**
- Hierarchical facility structure
- Location-specific configurations
- Cross-facility reporting
- Centralized management

### **📊 Business Intelligence**
- Sales analytics and trends
- User engagement metrics
- Operational reports
- Financial dashboards

### **🔒 Security & Compliance**
- bcrypt password hashing
- JWT session management
- Audit logging
- GDPR-compliant data handling

---

## 🗄️ **Database & Setup**

Complete database setup instructions and SQL scripts are available in:
**📁 [`vertic/SQL/README.md`](vertic/SQL/README.md)**

### **Production-Ready Setup**
- ✅ **33 RBAC Permissions** across 6 categories
- ✅ **5 Standard Roles** (Super Admin, Facility Admin, etc.)
- ✅ **Unified Authentication** system
- ✅ **Comprehensive Troubleshooting** guide

---

## 🔧 **Development**

### **Project Structure**
```
vertic_app/
├── 📁 Datenbankentwurf/          # Database design docs
├── 📁 docs/                     # Project documentation  
├── 📁 vertic/
│   ├── 📁 SQL/                  # Database setup scripts
│   ├── 📁 vertic_project/       # Flutter applications
│   │   ├── 📁 vertic_staff_app/ # Staff management app
│   │   └── 📁 vertic_client_app/# Customer app
│   └── 📁 vertic_server/        # Serverpod backend
│       ├── 📁 vertic_server_client/  # Client SDK
│       └── 📁 vertic_server_server/  # Server logic
└── 📄 pubspec.yaml              # Project dependencies
```

### **Contributing**
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

---

## 📦 **Deployment**

### **Production Checklist**
- [ ] Database migrations applied
- [ ] RBAC system initialized
- [ ] Superuser account secured
- [ ] Environment variables configured
- [ ] SSL certificates installed
- [ ] Backup strategy implemented

### **Infrastructure**
- **Backend**: Dart/Serverpod server
- **Database**: PostgreSQL cluster
- **Frontend**: Flutter web/mobile deployments
- **Monitoring**: Integrated logging and metrics

---

## 🎯 **Current Status**

**✅ PRODUCTION READY**
- Complete authentication system with bcrypt
- Full RBAC implementation (53 permissions active)
- Staff app fully functional
- Database setup automated
- Comprehensive documentation

---

## 📞 **Support & Contact**

- **Repository**: [github.com/LeonStadler/vertic_app](https://github.com/LeonStadler/vertic_app)
- **Documentation**: [SQL Setup Guide](vertic/SQL/README.md)
- **Issues**: Use GitHub Issues for bug reports and feature requests

---

## 📄 **License**

This project is proprietary software developed for sports facility management.

---

**🚀 Ready for production deployment with comprehensive authentication, RBAC, and multi-facility support!** 