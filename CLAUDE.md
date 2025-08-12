# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Vertic is a comprehensive digital sports facility management system built with Flutter and Serverpod, designed for venues like bouldering halls. It features two main applications:

- **Staff App** (`vertic_app/vertic/vertic_project/vertic_staff_app/`) - Administrative interface with POS system, user management, and analytics
- **Client App** (`vertic_app/vertic/vertic_project/vertic_client_app/`) - Customer-facing app for ticket purchasing and facility access

## Architecture

### Backend (Serverpod 2.9+)
- **Server**: `vertic_app/vertic/vertic_server/vertic_server_server/`
- **Client SDK**: `vertic_app/vertic/vertic_server/vertic_server_client/`
- **Database**: PostgreSQL with comprehensive RBAC system (53+ permissions across 8 categories)
- **Authentication**: Custom staff authentication with JWT tokens and bcrypt password hashing

### Frontend (Flutter 3.8+)
- **Staff App**: Administrative interface with role-based access control
- **Client App**: Customer app with QR code generation, ticket purchasing, camera integration
- **State Management**: Provider pattern with custom providers for auth and session management
- **Design System**: Custom Vertic theme with dark/light mode support

## Essential Development Commands

### Backend (Serverpod)
```bash
# Navigate to server directory
cd vertic_app/vertic/vertic_server/vertic_server_server

# Generate code and apply migrations (full workflow)
serverpod generate && serverpod create-migration && dart pub get && dart run bin/main.dart --apply-migrations

# Start server
dart run bin/main.dart

# Start server with migrations
dart run bin/main.dart --apply-migrations
```

### Frontend (Flutter)
```bash
# Staff App
cd vertic_app/vertic/vertic_project/vertic_staff_app
flutter clean && flutter pub get && flutter run

# Client App  
cd vertic_app/vertic/vertic_project/vertic_client_app
flutter clean && flutter pub get && flutter run

# For macOS specifically
flutter clean && flutter pub get && flutter run -d mac
```

### Development Workflow
```bash
# Quick restart for frontend
clear; flutter pub get; flutter run
```

## Database Configuration

### Connection Details
- **Host**: `159.69.144.208:5432` (remote Hetzner database)
- **Database**: `vertic`
- **User**: `vertic_dev`
- **Environment**: Development uses remote database for team collaboration

### Setup
1. Execute `vertic_app/vertic/SQL/COMPLETE_VERTIC_SETUP.sql` in pgAdmin4
2. Creates complete RBAC system with 53+ permissions (no predefined roles)
3. Creates superuser account: `superuser` / `super123`
4. All roles are created dynamically by the superuser - there are NO hardcoded roles except superuser

### Key SQL Scripts
- `COMPLETE_VERTIC_SETUP.sql` - Complete database initialization
- `REPAIR_TOOLS.sql` - Fixes common authentication issues  
- Various debug scripts for troubleshooting staff permissions

## Critical Development Rules

### Dependency Management (MANDATORY)
- **NEVER modify dependencies** without checking ALL apps first
- Run `grep -r "package_name" vertic_project/` before any dependency changes
- CREATE NEW instead of MODIFY EXISTING shared components
- Document ALL usages before modification

### Serverpod Workflow
- **ALWAYS** analyze existing `.spy` files before writing endpoint code
- Use ONLY fields defined and generated in models
- Missing fields: Define in `.spy` file → `serverpod generate` → write endpoint code
- Follow migration-first development: Model changes → Generate → Create migration → Apply

### Code Standards
- Use existing dependencies from `pubspec.yaml` when possible
- Follow established naming conventions (`lowerCamelCase` for constants)
- Implement comprehensive error handling with `try-catch` blocks
- Use `const` constructors for widgets where possible
- NO `print()` statements in production code - use proper logging
- Remove all TODO comments before commits

### Permission System
- Use string-based permission keys (legacy system)
- All permissions defined in backend seeder
- Frontend uses `PermissionWrapper` widgets for access control
- 53+ permissions across categories: staff management, user management, product management, ticket management, system settings, RBAC management, facility management, DACH compliance

## Architecture Patterns

### State Management
- Provider pattern with custom providers
- `StaffAuthProvider` for authentication state
- `PermissionProvider` for role-based access control
- Reactive UI updates based on state changes

### Authentication Flow
1. Staff login via `StaffAuthProvider`
2. Token storage in secure storage
3. Session management with device ID tracking
4. Permission checking through `PermissionWrapper`

### Database Patterns
- Use Serverpod's built-in query builder
- Implement proper transactions for atomic operations
- Use includes for eager loading relationships
- Index critical query paths for performance

## Security Considerations

- All passwords hashed with bcrypt
- JWT tokens for session management
- Role-based access control (RBAC) throughout system
- Input validation on both client and server sides
- Secure token storage using `flutter_secure_storage`
- Device ID tracking for session security

## Testing Strategy

- Widget tests for UI components
- Unit tests for business logic
- Integration tests for API endpoints
- Permission synchronization tests between frontend and backend

## Environment Configuration

### Development
- Local Serverpod server on `localhost:8080`
- Remote PostgreSQL database on Hetzner
- Development configuration in `config/development.yaml`

### Key Environment Files
- `config/development.yaml` - Database and server configuration
- `config/passwords.yaml` - Database credentials
- Analysis options defined in `analysis_options.yaml` files

## Common Issues & Solutions

### Authentication Problems
- Run `REPAIR_TOOLS.sql` to fix common auth issues
- Check staff user exists in database
- Verify permissions are properly assigned

### Permission Mismatches  
- Frontend permission checks may reference non-existent permissions
- Cross-reference with backend permission seeder
- Use exact permission key strings from backend

### Database Connection Issues
- Verify `config/development.yaml` has correct host (`159.69.144.208`)
- Check `config/passwords.yaml` for correct database credentials
- Ensure PostgreSQL server is accessible

## Development Best Practices

### Before Making Changes
1. Use `grep` to find all usages of components you plan to modify
2. Check both staff and client apps for dependencies
3. Review existing patterns and follow them consistently
4. Test changes in both applications

### Code Organization
- Follow existing folder structure patterns
- Separate business logic from UI components
- Use consistent naming across similar components
- Implement proper error boundaries and loading states

### Database Changes
1. Modify `.spy.yaml` files for model changes
2. Run `serverpod generate`
3. Create migration with `serverpod create-migration`
4. Review generated SQL before applying
5. Apply with `--apply-migrations` flag

This codebase uses a shared remote database for team development while maintaining local Serverpod servers for fast development cycles. Always coordinate database changes with team members and test thoroughly before applying migrations.