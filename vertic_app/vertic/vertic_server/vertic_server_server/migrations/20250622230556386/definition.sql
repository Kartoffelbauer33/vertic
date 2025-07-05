BEGIN;

--
-- Class AccountCleanupLog as table account_cleanup_logs
--
CREATE TABLE "account_cleanup_logs" (
    "id" bigserial PRIMARY KEY,
    "cleanupDate" timestamp without time zone NOT NULL,
    "accountsDeleted" bigint NOT NULL,
    "criteriaUsed" text NOT NULL,
    "detailsJson" text,
    "triggeredBy" text NOT NULL
);

-- Indexes
CREATE INDEX "cleanup_log_date_idx" ON "account_cleanup_logs" USING btree ("cleanupDate");

--
-- Class AppUser as table app_users
--
CREATE TABLE "app_users" (
    "id" bigserial PRIMARY KEY,
    "userInfoId" bigint,
    "firstName" text NOT NULL,
    "lastName" text NOT NULL,
    "email" text,
    "parentEmail" text,
    "gender" text,
    "address" text,
    "city" text,
    "postalCode" text,
    "phoneNumber" text,
    "birthDate" timestamp without time zone,
    "primaryStatusId" bigint,
    "profilePhoto" bytea,
    "photoUploadedAt" timestamp without time zone,
    "photoApprovedBy" bigint,
    "accountStatus" text NOT NULL DEFAULT 'pending_verification'::text,
    "verificationCode" text,
    "verificationCodeExpiry" timestamp without time zone,
    "verificationAttempts" bigint NOT NULL DEFAULT 0,
    "passwordHash" text,
    "isManuallyApproved" boolean NOT NULL DEFAULT false,
    "approvedBy" bigint,
    "approvedAt" timestamp without time zone,
    "approvalReason" text,
    "isMinor" boolean NOT NULL DEFAULT false,
    "requiresParentalConsent" boolean NOT NULL DEFAULT false,
    "parentNotified" boolean NOT NULL DEFAULT false,
    "parentApproved" boolean NOT NULL DEFAULT false,
    "isBlocked" boolean NOT NULL DEFAULT false,
    "blockedReason" text,
    "blockedAt" timestamp without time zone,
    "isEmailVerified" boolean NOT NULL DEFAULT false,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone,
    "lastLoginAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "app_user_email_idx" ON "app_users" USING btree ("email");
CREATE INDEX "app_user_parent_email_idx" ON "app_users" USING btree ("parentEmail");
CREATE UNIQUE INDEX "app_user_userinfo_idx" ON "app_users" USING btree ("userInfoId");
CREATE INDEX "app_user_status_idx" ON "app_users" USING btree ("accountStatus");
CREATE INDEX "app_user_verification_code_idx" ON "app_users" USING btree ("verificationCode");
CREATE INDEX "app_user_blocked_idx" ON "app_users" USING btree ("isBlocked");
CREATE INDEX "app_user_manual_approval_idx" ON "app_users" USING btree ("isManuallyApproved");
CREATE INDEX "app_user_minor_idx" ON "app_users" USING btree ("isMinor");
CREATE INDEX "app_user_created_idx" ON "app_users" USING btree ("createdAt");
CREATE INDEX "app_user_primary_status_idx" ON "app_users" USING btree ("primaryStatusId");
CREATE INDEX "app_user_photo_idx" ON "app_users" USING btree ("photoUploadedAt");

--
-- Class BillingConfiguration as table billing_configurations
--
CREATE TABLE "billing_configurations" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text NOT NULL,
    "billingType" text NOT NULL,
    "billingDay" bigint NOT NULL,
    "billingDayOfYear" bigint,
    "customIntervalDays" bigint,
    "isActive" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "billing_config_name_unique_idx" ON "billing_configurations" USING btree ("name");
CREATE INDEX "billing_config_active_idx" ON "billing_configurations" USING btree ("isActive");

--
-- Class ClientDocumentAgreement as table client_document_agreements
--
CREATE TABLE "client_document_agreements" (
    "id" bigserial PRIMARY KEY,
    "clientId" bigint NOT NULL,
    "documentId" bigint NOT NULL,
    "agreedAt" timestamp without time zone NOT NULL,
    "ipAddress" text,
    "userAgent" text,
    "documentVersion" text,
    "isRevoked" boolean NOT NULL,
    "revokedAt" timestamp without time zone
);

--
-- Class DocumentDisplayRule as table document_display_rules
--
CREATE TABLE "document_display_rules" (
    "id" bigserial PRIMARY KEY,
    "documentId" bigint NOT NULL,
    "ruleName" text NOT NULL,
    "description" text,
    "minAge" bigint,
    "maxAge" bigint,
    "gymId" bigint,
    "isRequired" boolean NOT NULL,
    "isActive" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

--
-- Class Facility as table facilities
--
CREATE TABLE "facilities" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text,
    "address" text,
    "city" text,
    "postalCode" text,
    "contactEmail" text,
    "contactPhone" text,
    "isActive" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "facility_name_unique_idx" ON "facilities" USING btree ("name");

--
-- Class FacilityModuleConfig as table facility_module_configs
--
CREATE TABLE "facility_module_configs" (
    "id" bigserial PRIMARY KEY,
    "facilityId" bigint NOT NULL,
    "moduleKey" text NOT NULL,
    "isEnabled" boolean NOT NULL DEFAULT true,
    "configData" text,
    "subscriptionType" text,
    "validFrom" timestamp without time zone NOT NULL,
    "validUntil" timestamp without time zone,
    "maxUsers" bigint,
    "maxTransactions" bigint,
    "notes" text,
    "createdBy" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "facility_module_facility_idx" ON "facility_module_configs" USING btree ("facilityId");
CREATE INDEX "facility_module_key_idx" ON "facility_module_configs" USING btree ("moduleKey");
CREATE INDEX "facility_module_enabled_idx" ON "facility_module_configs" USING btree ("isEnabled");
CREATE UNIQUE INDEX "facility_module_unique_idx" ON "facility_module_configs" USING btree ("facilityId", "moduleKey");
CREATE INDEX "facility_module_subscription_idx" ON "facility_module_configs" USING btree ("subscriptionType");
CREATE INDEX "facility_module_valid_from_idx" ON "facility_module_configs" USING btree ("validFrom");
CREATE INDEX "facility_module_valid_until_idx" ON "facility_module_configs" USING btree ("validUntil");

--
-- Class Gym as table gyms
--
CREATE TABLE "gyms" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "shortCode" text NOT NULL,
    "city" text NOT NULL,
    "address" text,
    "description" text,
    "facilityId" bigint,
    "isActive" boolean NOT NULL DEFAULT true,
    "isVerticLocation" boolean NOT NULL DEFAULT true,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "gym_short_code_unique_idx" ON "gyms" USING btree ("shortCode");
CREATE INDEX "gym_name_idx" ON "gyms" USING btree ("name");
CREATE INDEX "gym_facility_idx" ON "gyms" USING btree ("facilityId");

--
-- Class HallInfo as table hall_info
--
CREATE TABLE "hall_info" (
    "id" bigserial PRIMARY KEY,
    "hallName" text NOT NULL,
    "isVisible" boolean NOT NULL,
    "einzeltickets" json NOT NULL,
    "punktekarten" json NOT NULL,
    "zeitkarten" json NOT NULL
);

--
-- Class HierarchicalTicketResponse as table hierarchical_ticket_response
--
CREATE TABLE "hierarchical_ticket_response" (
    "id" bigserial PRIMARY KEY,
    "vertic" json NOT NULL,
    "bregenz" json NOT NULL,
    "friedrichshafen" json NOT NULL
);

--
-- Class Permission as table permissions
--
CREATE TABLE "permissions" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "displayName" text NOT NULL,
    "description" text,
    "category" text NOT NULL,
    "isSystemCritical" boolean NOT NULL DEFAULT false,
    "iconName" text,
    "color" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "permission_name_unique_idx" ON "permissions" USING btree ("name");
CREATE INDEX "permission_category_idx" ON "permissions" USING btree ("category");

--
-- Class PrinterConfiguration as table printer_configurations
--
CREATE TABLE "printer_configurations" (
    "id" bigserial PRIMARY KEY,
    "facilityId" bigint,
    "printerName" text NOT NULL,
    "printerType" text NOT NULL,
    "connectionType" text NOT NULL,
    "connectionSettings" text NOT NULL,
    "paperSize" text NOT NULL,
    "isDefault" boolean NOT NULL,
    "isActive" boolean NOT NULL,
    "testPrintEnabled" boolean NOT NULL,
    "createdBy" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "printer_facility_idx" ON "printer_configurations" USING btree ("facilityId");
CREATE INDEX "printer_default_idx" ON "printer_configurations" USING btree ("isDefault");
CREATE INDEX "printer_active_idx" ON "printer_configurations" USING btree ("isActive");

--
-- Class PurchaseStatusResponse as table purchase_status_response
--
CREATE TABLE "purchase_status_response" (
    "id" bigserial PRIMARY KEY,
    "hasPurchased" boolean NOT NULL,
    "canPurchaseAgain" boolean NOT NULL,
    "isPrintingPending" boolean NOT NULL,
    "lastPurchaseDate" timestamp without time zone,
    "ticketId" bigint,
    "qrCodeData" text
);

--
-- Class QrRotationPolicy as table qr_rotation_policies
--
CREATE TABLE "qr_rotation_policies" (
    "id" bigserial PRIMARY KEY,
    "policyName" text NOT NULL,
    "rotationMode" text NOT NULL,
    "rotationIntervalHours" bigint,
    "requiresUsageForRotation" boolean NOT NULL,
    "maxUsageBeforeRotation" bigint,
    "isDefault" boolean NOT NULL,
    "description" text,
    "isActive" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "qr_policy_name_idx" ON "qr_rotation_policies" USING btree ("policyName");
CREATE INDEX "qr_policy_default_idx" ON "qr_rotation_policies" USING btree ("isDefault");

--
-- Class RegistrationDocument as table registration_documents
--
CREATE TABLE "registration_documents" (
    "id" bigserial PRIMARY KEY,
    "title" text NOT NULL,
    "description" text,
    "documentType" text NOT NULL,
    "pdfData" bytea NOT NULL,
    "fileName" text NOT NULL,
    "fileSize" bigint NOT NULL,
    "uploadedByStaffId" bigint,
    "isActive" boolean NOT NULL,
    "sortOrder" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

--
-- Class RolePermission as table role_permissions
--
CREATE TABLE "role_permissions" (
    "id" bigserial PRIMARY KEY,
    "roleId" bigint NOT NULL,
    "permissionId" bigint NOT NULL,
    "assignedAt" timestamp without time zone NOT NULL,
    "assignedBy" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "role_permission_unique_idx" ON "role_permissions" USING btree ("roleId", "permissionId");
CREATE INDEX "role_permissions_idx" ON "role_permissions" USING btree ("roleId");
CREATE INDEX "permission_roles_idx" ON "role_permissions" USING btree ("permissionId");

--
-- Class Role as table roles
--
CREATE TABLE "roles" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "displayName" text NOT NULL,
    "description" text,
    "color" text,
    "iconName" text,
    "isSystemRole" boolean NOT NULL DEFAULT false,
    "isActive" boolean NOT NULL DEFAULT true,
    "sortOrder" bigint NOT NULL DEFAULT 0,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone,
    "createdBy" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "role_name_unique_idx" ON "roles" USING btree ("name");
CREATE INDEX "role_active_sort_idx" ON "roles" USING btree ("isActive", "sortOrder");

--
-- Class StaffToken as table staff_tokens
--
CREATE TABLE "staff_tokens" (
    "id" bigserial PRIMARY KEY,
    "staffUserId" bigint NOT NULL,
    "token" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "valid" boolean NOT NULL
);

--
-- Class StaffUserPermission as table staff_user_permissions
--
CREATE TABLE "staff_user_permissions" (
    "id" bigserial PRIMARY KEY,
    "staffUserId" bigint NOT NULL,
    "permissionId" bigint NOT NULL,
    "grantedAt" timestamp without time zone NOT NULL,
    "grantedBy" bigint NOT NULL,
    "expiresAt" timestamp without time zone,
    "isActive" boolean NOT NULL DEFAULT true,
    "reason" text,
    "notes" text
);

-- Indexes
CREATE UNIQUE INDEX "staff_permission_unique_idx" ON "staff_user_permissions" USING btree ("staffUserId", "permissionId");
CREATE INDEX "staff_user_permission_idx" ON "staff_user_permissions" USING btree ("staffUserId");
CREATE INDEX "permission_staff_idx" ON "staff_user_permissions" USING btree ("permissionId");
CREATE INDEX "active_staff_permissions_idx" ON "staff_user_permissions" USING btree ("isActive", "expiresAt");

--
-- Class StaffUserRole as table staff_user_roles
--
CREATE TABLE "staff_user_roles" (
    "id" bigserial PRIMARY KEY,
    "staffUserId" bigint NOT NULL,
    "roleId" bigint NOT NULL,
    "assignedAt" timestamp without time zone NOT NULL,
    "assignedBy" bigint NOT NULL,
    "isActive" boolean NOT NULL DEFAULT true,
    "expiresAt" timestamp without time zone,
    "reason" text
);

-- Indexes
CREATE UNIQUE INDEX "staff_role_unique_idx" ON "staff_user_roles" USING btree ("staffUserId", "roleId");
CREATE INDEX "staff_user_roles_idx" ON "staff_user_roles" USING btree ("staffUserId");
CREATE INDEX "role_staff_users_idx" ON "staff_user_roles" USING btree ("roleId");
CREATE INDEX "active_staff_roles_idx" ON "staff_user_roles" USING btree ("isActive", "expiresAt");

--
-- Class StaffUser as table staff_users
--
CREATE TABLE "staff_users" (
    "id" bigserial PRIMARY KEY,
    "userInfoId" bigint,
    "firstName" text NOT NULL,
    "lastName" text NOT NULL,
    "email" text NOT NULL,
    "phoneNumber" text,
    "employeeId" text,
    "socialSecurityNumber" text,
    "birthDate" timestamp without time zone,
    "contractType" text,
    "hourlyRate" double precision,
    "monthlySalary" double precision,
    "contractStartDate" timestamp without time zone,
    "contractEndDate" timestamp without time zone,
    "workingHours" bigint,
    "shiftModel" text,
    "availabilityData" text,
    "qualifications" text,
    "certifications" text,
    "languages" text,
    "bankIban" text,
    "bankBic" text,
    "bankAccountHolder" text,
    "taxId" text,
    "taxClass" text,
    "address" text,
    "city" text,
    "postalCode" text,
    "emergencyContact" text,
    "staffLevel" bigint NOT NULL,
    "departmentId" bigint,
    "hallId" bigint,
    "facilityId" bigint,
    "passwordHash" text,
    "lastLoginAt" timestamp without time zone,
    "loginAttempts" bigint NOT NULL DEFAULT 0,
    "isAccountLocked" boolean NOT NULL DEFAULT false,
    "lockoutUntil" timestamp without time zone,
    "employmentStatus" text NOT NULL DEFAULT 'active'::text,
    "terminationDate" timestamp without time zone,
    "terminationReason" text,
    "emailVerifiedAt" timestamp without time zone,
    "createdBy" bigint,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone,
    "updatedBy" bigint,
    "notes" text,
    "documentsJson" text
);

-- Indexes
CREATE UNIQUE INDEX "staff_user_email_idx" ON "staff_users" USING btree ("email");
CREATE UNIQUE INDEX "staff_user_employee_id_idx" ON "staff_users" USING btree ("employeeId");
CREATE UNIQUE INDEX "staff_user_userinfo_idx" ON "staff_users" USING btree ("userInfoId");
CREATE INDEX "staff_user_level_idx" ON "staff_users" USING btree ("staffLevel");
CREATE INDEX "staff_user_department_idx" ON "staff_users" USING btree ("departmentId");
CREATE INDEX "staff_user_hall_idx" ON "staff_users" USING btree ("hallId");
CREATE INDEX "staff_user_facility_idx" ON "staff_users" USING btree ("facilityId");
CREATE INDEX "staff_user_status_idx" ON "staff_users" USING btree ("employmentStatus");
CREATE INDEX "staff_user_created_idx" ON "staff_users" USING btree ("createdAt");
CREATE INDEX "staff_user_login_idx" ON "staff_users" USING btree ("lastLoginAt");

--
-- Class StatusHierarchyResponse as table status_hierarchy_response
--
CREATE TABLE "status_hierarchy_response" (
    "id" bigserial PRIMARY KEY,
    "success" boolean NOT NULL,
    "totalStatusTypes" bigint NOT NULL,
    "totalGyms" bigint NOT NULL,
    "totalFacilities" bigint NOT NULL,
    "universalStatusCount" bigint NOT NULL,
    "facilitiesJson" text,
    "statusTypesJson" text,
    "gymsJson" text,
    "error" text
);

--
-- Class SystemSetting as table system_settings
--
CREATE TABLE "system_settings" (
    "id" bigserial PRIMARY KEY,
    "settingKey" text NOT NULL,
    "settingValue" text NOT NULL,
    "settingType" text NOT NULL,
    "description" text,
    "isUserConfigurable" boolean NOT NULL,
    "isSuperAdminOnly" boolean NOT NULL,
    "lastModifiedBy" bigint,
    "lastModifiedAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "system_setting_key_idx" ON "system_settings" USING btree ("settingKey");
CREATE INDEX "system_setting_type_idx" ON "system_settings" USING btree ("settingType");

--
-- Class TicketCategoryInfo as table ticket_category_info
--
CREATE TABLE "ticket_category_info" (
    "id" bigserial PRIMARY KEY,
    "categoryName" text NOT NULL,
    "isVisible" boolean NOT NULL,
    "ticketCount" bigint NOT NULL,
    "tickets" json NOT NULL
);

--
-- Class TicketTypePricing as table ticket_type_pricing
--
CREATE TABLE "ticket_type_pricing" (
    "id" bigserial PRIMARY KEY,
    "ticketTypeId" bigint NOT NULL,
    "userStatusTypeId" bigint NOT NULL,
    "price" double precision NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "ticket_type_id_idx" ON "ticket_type_pricing" USING btree ("ticketTypeId");
CREATE INDEX "user_status_type_id_idx" ON "ticket_type_pricing" USING btree ("userStatusTypeId");
CREATE UNIQUE INDEX "unique_combination_idx" ON "ticket_type_pricing" USING btree ("ticketTypeId", "userStatusTypeId");

--
-- Class TicketType as table ticket_types
--
CREATE TABLE "ticket_types" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text NOT NULL,
    "validityPeriod" bigint NOT NULL,
    "defaultPrice" double precision NOT NULL,
    "isPointBased" boolean NOT NULL,
    "defaultPoints" bigint,
    "isSubscription" boolean NOT NULL,
    "billingInterval" bigint,
    "gymId" bigint,
    "isVerticUniversal" boolean NOT NULL DEFAULT false,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "ticket_type_name_unique_idx" ON "ticket_types" USING btree ("name");
CREATE INDEX "ticket_type_gym_idx" ON "ticket_types" USING btree ("gymId");
CREATE INDEX "ticket_type_vertic_idx" ON "ticket_types" USING btree ("isVerticUniversal");

--
-- Class TicketUsageLog as table ticket_usage_log
--
CREATE TABLE "ticket_usage_log" (
    "id" bigserial PRIMARY KEY,
    "ticketId" bigint NOT NULL,
    "usageDate" timestamp without time zone NOT NULL,
    "pointsUsed" bigint NOT NULL,
    "facilityId" bigint,
    "staffId" bigint,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "ticket_usage_ticket_idx" ON "ticket_usage_log" USING btree ("ticketId");
CREATE INDEX "ticket_usage_date_idx" ON "ticket_usage_log" USING btree ("usageDate");

--
-- Class TicketVisibilitySetting as table ticket_visibility_settings
--
CREATE TABLE "ticket_visibility_settings" (
    "id" bigserial PRIMARY KEY,
    "ticketTypeId" bigint,
    "facilityId" bigint,
    "categoryType" text,
    "isVisibleToClients" boolean NOT NULL,
    "displayOrder" bigint NOT NULL,
    "customDescription" text,
    "isPromoted" boolean NOT NULL,
    "availableFrom" timestamp without time zone,
    "availableUntil" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "ticket_visibility_type_facility_idx" ON "ticket_visibility_settings" USING btree ("ticketTypeId", "facilityId");
CREATE INDEX "ticket_visibility_category_idx" ON "ticket_visibility_settings" USING btree ("categoryType", "facilityId");
CREATE INDEX "ticket_visibility_order_idx" ON "ticket_visibility_settings" USING btree ("displayOrder");

--
-- Class Ticket as table tickets
--
CREATE TABLE "tickets" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "ticketTypeId" bigint NOT NULL,
    "price" double precision NOT NULL,
    "purchaseDate" timestamp without time zone NOT NULL,
    "expiryDate" timestamp without time zone NOT NULL,
    "isUsed" boolean NOT NULL,
    "remainingPoints" bigint,
    "initialPoints" bigint,
    "subscriptionStatus" text,
    "lastBillingDate" timestamp without time zone,
    "nextBillingDate" timestamp without time zone,
    "qrCodeData" text NOT NULL,
    "activatedDate" timestamp without time zone,
    "activatedForDate" timestamp without time zone,
    "currentUsageCount" bigint NOT NULL DEFAULT 0,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "tickets_user_idx" ON "tickets" USING btree ("userId");
CREATE INDEX "tickets_type_idx" ON "tickets" USING btree ("ticketTypeId");
CREATE INDEX "tickets_expiry_idx" ON "tickets" USING btree ("expiryDate");
CREATE INDEX "tickets_activated_idx" ON "tickets" USING btree ("activatedForDate");
CREATE INDEX "tickets_qr_idx" ON "tickets" USING btree ("qrCodeData");

--
-- Class UserIdentity as table user_identities
--
CREATE TABLE "user_identities" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "qrCodeData" text NOT NULL,
    "qrCodeGenerated" timestamp without time zone NOT NULL,
    "lastUsed" timestamp without time zone,
    "usageCount" bigint NOT NULL,
    "isActive" boolean NOT NULL,
    "rotationPolicyId" bigint,
    "nextRotationDue" timestamp without time zone,
    "forceRotationAfterUsage" boolean NOT NULL,
    "unlockExpiry" timestamp without time zone,
    "requiresUnlock" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "user_identity_user_idx" ON "user_identities" USING btree ("userId");
CREATE INDEX "user_identity_active_idx" ON "user_identities" USING btree ("isActive");
CREATE INDEX "user_identity_rotation_due_idx" ON "user_identities" USING btree ("nextRotationDue");

--
-- Class UserNote as table user_notes
--
CREATE TABLE "user_notes" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "noteType" text NOT NULL,
    "content" text NOT NULL,
    "isInternal" boolean NOT NULL DEFAULT true,
    "priority" text NOT NULL DEFAULT 'normal'::text,
    "createdByStaffId" bigint,
    "createdByName" text,
    "status" text NOT NULL DEFAULT 'active'::text,
    "tags" text,
    "relatedTicketId" bigint,
    "relatedStatusId" bigint,
    "ipAddress" text,
    "userAgent" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone,
    "resolvedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "user_note_user_idx" ON "user_notes" USING btree ("userId");
CREATE INDEX "user_note_staff_idx" ON "user_notes" USING btree ("createdByStaffId");
CREATE INDEX "user_note_type_idx" ON "user_notes" USING btree ("noteType");
CREATE INDEX "user_note_priority_idx" ON "user_notes" USING btree ("priority");
CREATE INDEX "user_note_status_idx" ON "user_notes" USING btree ("status");
CREATE INDEX "user_note_created_idx" ON "user_notes" USING btree ("createdAt");
CREATE INDEX "user_note_ticket_idx" ON "user_notes" USING btree ("relatedTicketId");
CREATE INDEX "user_note_user_status_idx" ON "user_notes" USING btree ("relatedStatusId");

--
-- Class UserPurchaseStatus as table user_purchase_statuses
--
CREATE TABLE "user_purchase_statuses" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "ticketTypeId" bigint NOT NULL,
    "lastPurchaseDate" timestamp without time zone NOT NULL,
    "isPrintingPending" boolean NOT NULL,
    "printJobId" text,
    "printedAt" timestamp without time zone,
    "ticketCount" bigint NOT NULL,
    "canPurchaseAgain" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "user_purchase_user_type_idx" ON "user_purchase_statuses" USING btree ("userId", "ticketTypeId");
CREATE INDEX "user_purchase_pending_idx" ON "user_purchase_statuses" USING btree ("isPrintingPending");

--
-- Class UserRelationship as table user_relationships
--
CREATE TABLE "user_relationships" (
    "id" bigserial PRIMARY KEY,
    "parentUserId" bigint NOT NULL,
    "childUserId" bigint NOT NULL,
    "relationshipType" text NOT NULL DEFAULT 'parent'::text,
    "canPurchaseTickets" boolean NOT NULL DEFAULT true,
    "canCancelSubscriptions" boolean NOT NULL DEFAULT true,
    "canManagePayments" boolean NOT NULL DEFAULT true,
    "canViewHistory" boolean NOT NULL DEFAULT true,
    "isActive" boolean NOT NULL DEFAULT true,
    "approvedBy" bigint,
    "approvedAt" timestamp without time zone,
    "approvalReason" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "user_rel_parent_idx" ON "user_relationships" USING btree ("parentUserId");
CREATE INDEX "user_rel_child_idx" ON "user_relationships" USING btree ("childUserId");
CREATE UNIQUE INDEX "user_rel_parent_child_unique_idx" ON "user_relationships" USING btree ("parentUserId", "childUserId");
CREATE INDEX "user_rel_active_idx" ON "user_relationships" USING btree ("isActive");

--
-- Class UserStatus as table user_status
--
CREATE TABLE "user_status" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "statusTypeId" bigint NOT NULL,
    "isVerified" boolean NOT NULL,
    "verifiedById" bigint,
    "verificationDate" timestamp without time zone,
    "expiryDate" timestamp without time zone,
    "documentationPath" text,
    "notes" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "user_status_user_idx" ON "user_status" USING btree ("userId");
CREATE INDEX "user_status_type_idx" ON "user_status" USING btree ("statusTypeId");
CREATE INDEX "is_verified_idx" ON "user_status" USING btree ("isVerified");
CREATE INDEX "verified_status_combined_idx" ON "user_status" USING btree ("userId", "statusTypeId", "isVerified");

--
-- Class UserStatusType as table user_status_types
--
CREATE TABLE "user_status_types" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text NOT NULL,
    "discountPercentage" double precision NOT NULL,
    "fixedDiscountAmount" double precision,
    "requiresVerification" boolean NOT NULL,
    "requiresDocumentation" boolean NOT NULL,
    "validityPeriod" bigint NOT NULL,
    "gymId" bigint,
    "isVerticUniversal" boolean NOT NULL DEFAULT false,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "user_status_type_name_unique_idx" ON "user_status_types" USING btree ("name");
CREATE INDEX "user_status_type_gym_idx" ON "user_status_types" USING btree ("gymId");
CREATE INDEX "user_status_type_vertic_idx" ON "user_status_types" USING btree ("isVerticUniversal");

--
-- Class CloudStorageEntry as table serverpod_cloud_storage
--
CREATE TABLE "serverpod_cloud_storage" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "addedTime" timestamp without time zone NOT NULL,
    "expiration" timestamp without time zone,
    "byteData" bytea NOT NULL,
    "verified" boolean NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_path_idx" ON "serverpod_cloud_storage" USING btree ("storageId", "path");
CREATE INDEX "serverpod_cloud_storage_expiration" ON "serverpod_cloud_storage" USING btree ("expiration");

--
-- Class CloudStorageDirectUploadEntry as table serverpod_cloud_storage_direct_upload
--
CREATE TABLE "serverpod_cloud_storage_direct_upload" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_upload_storage_path" ON "serverpod_cloud_storage_direct_upload" USING btree ("storageId", "path");

--
-- Class FutureCallEntry as table serverpod_future_call
--
CREATE TABLE "serverpod_future_call" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "serializedObject" text,
    "serverId" text NOT NULL,
    "identifier" text
);

-- Indexes
CREATE INDEX "serverpod_future_call_time_idx" ON "serverpod_future_call" USING btree ("time");
CREATE INDEX "serverpod_future_call_serverId_idx" ON "serverpod_future_call" USING btree ("serverId");
CREATE INDEX "serverpod_future_call_identifier_idx" ON "serverpod_future_call" USING btree ("identifier");

--
-- Class ServerHealthConnectionInfo as table serverpod_health_connection_info
--
CREATE TABLE "serverpod_health_connection_info" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "active" bigint NOT NULL,
    "closing" bigint NOT NULL,
    "idle" bigint NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_connection_info_timestamp_idx" ON "serverpod_health_connection_info" USING btree ("timestamp", "serverId", "granularity");

--
-- Class ServerHealthMetric as table serverpod_health_metric
--
CREATE TABLE "serverpod_health_metric" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "isHealthy" boolean NOT NULL,
    "value" double precision NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_metric_timestamp_idx" ON "serverpod_health_metric" USING btree ("timestamp", "serverId", "name", "granularity");

--
-- Class LogEntry as table serverpod_log
--
CREATE TABLE "serverpod_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "reference" text,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "logLevel" bigint NOT NULL,
    "message" text NOT NULL,
    "error" text,
    "stackTrace" text,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_log_sessionLogId_idx" ON "serverpod_log" USING btree ("sessionLogId");

--
-- Class MessageLogEntry as table serverpod_message_log
--
CREATE TABLE "serverpod_message_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "serverId" text NOT NULL,
    "messageId" bigint NOT NULL,
    "endpoint" text NOT NULL,
    "messageName" text NOT NULL,
    "duration" double precision NOT NULL,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

--
-- Class MethodInfo as table serverpod_method
--
CREATE TABLE "serverpod_method" (
    "id" bigserial PRIMARY KEY,
    "endpoint" text NOT NULL,
    "method" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_method_endpoint_method_idx" ON "serverpod_method" USING btree ("endpoint", "method");

--
-- Class DatabaseMigrationVersion as table serverpod_migrations
--
CREATE TABLE "serverpod_migrations" (
    "id" bigserial PRIMARY KEY,
    "module" text NOT NULL,
    "version" text NOT NULL,
    "timestamp" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_migrations_ids" ON "serverpod_migrations" USING btree ("module");

--
-- Class QueryLogEntry as table serverpod_query_log
--
CREATE TABLE "serverpod_query_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "query" text NOT NULL,
    "duration" double precision NOT NULL,
    "numRows" bigint,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_query_log_sessionLogId_idx" ON "serverpod_query_log" USING btree ("sessionLogId");

--
-- Class ReadWriteTestEntry as table serverpod_readwrite_test
--
CREATE TABLE "serverpod_readwrite_test" (
    "id" bigserial PRIMARY KEY,
    "number" bigint NOT NULL
);

--
-- Class RuntimeSettings as table serverpod_runtime_settings
--
CREATE TABLE "serverpod_runtime_settings" (
    "id" bigserial PRIMARY KEY,
    "logSettings" json NOT NULL,
    "logSettingsOverrides" json NOT NULL,
    "logServiceCalls" boolean NOT NULL,
    "logMalformedCalls" boolean NOT NULL
);

--
-- Class SessionLogEntry as table serverpod_session_log
--
CREATE TABLE "serverpod_session_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "module" text,
    "endpoint" text,
    "method" text,
    "duration" double precision,
    "numQueries" bigint,
    "slow" boolean,
    "error" text,
    "stackTrace" text,
    "authenticatedUserId" bigint,
    "isOpen" boolean,
    "touched" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_session_log_serverid_idx" ON "serverpod_session_log" USING btree ("serverId");
CREATE INDEX "serverpod_session_log_touched_idx" ON "serverpod_session_log" USING btree ("touched");
CREATE INDEX "serverpod_session_log_isopen_idx" ON "serverpod_session_log" USING btree ("isOpen");

--
-- Class AuthKey as table serverpod_auth_key
--
CREATE TABLE "serverpod_auth_key" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "hash" text NOT NULL,
    "scopeNames" json NOT NULL,
    "method" text NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_auth_key_userId_idx" ON "serverpod_auth_key" USING btree ("userId");

--
-- Class EmailAuth as table serverpod_email_auth
--
CREATE TABLE "serverpod_email_auth" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "email" text NOT NULL,
    "hash" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_email_auth_email" ON "serverpod_email_auth" USING btree ("email");

--
-- Class EmailCreateAccountRequest as table serverpod_email_create_request
--
CREATE TABLE "serverpod_email_create_request" (
    "id" bigserial PRIMARY KEY,
    "userName" text NOT NULL,
    "email" text NOT NULL,
    "hash" text NOT NULL,
    "verificationCode" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_email_auth_create_account_request_idx" ON "serverpod_email_create_request" USING btree ("email");

--
-- Class EmailFailedSignIn as table serverpod_email_failed_sign_in
--
CREATE TABLE "serverpod_email_failed_sign_in" (
    "id" bigserial PRIMARY KEY,
    "email" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "ipAddress" text NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_email_failed_sign_in_email_idx" ON "serverpod_email_failed_sign_in" USING btree ("email");
CREATE INDEX "serverpod_email_failed_sign_in_time_idx" ON "serverpod_email_failed_sign_in" USING btree ("time");

--
-- Class EmailReset as table serverpod_email_reset
--
CREATE TABLE "serverpod_email_reset" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "verificationCode" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_email_reset_verification_idx" ON "serverpod_email_reset" USING btree ("verificationCode");

--
-- Class GoogleRefreshToken as table serverpod_google_refresh_token
--
CREATE TABLE "serverpod_google_refresh_token" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "refreshToken" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_google_refresh_token_userId_idx" ON "serverpod_google_refresh_token" USING btree ("userId");

--
-- Class UserImage as table serverpod_user_image
--
CREATE TABLE "serverpod_user_image" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "version" bigint NOT NULL,
    "url" text NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_user_image_user_id" ON "serverpod_user_image" USING btree ("userId", "version");

--
-- Class UserInfo as table serverpod_user_info
--
CREATE TABLE "serverpod_user_info" (
    "id" bigserial PRIMARY KEY,
    "userIdentifier" text NOT NULL,
    "userName" text,
    "fullName" text,
    "email" text,
    "created" timestamp without time zone NOT NULL,
    "imageUrl" text,
    "scopeNames" json NOT NULL,
    "blocked" boolean NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_user_info_user_identifier" ON "serverpod_user_info" USING btree ("userIdentifier");
CREATE INDEX "serverpod_user_info_email" ON "serverpod_user_info" USING btree ("email");

--
-- Foreign relations for "role_permissions" table
--
ALTER TABLE ONLY "role_permissions"
    ADD CONSTRAINT "role_permissions_fk_0"
    FOREIGN KEY("roleId")
    REFERENCES "roles"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "role_permissions"
    ADD CONSTRAINT "role_permissions_fk_1"
    FOREIGN KEY("permissionId")
    REFERENCES "permissions"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "role_permissions"
    ADD CONSTRAINT "role_permissions_fk_2"
    FOREIGN KEY("assignedBy")
    REFERENCES "staff_users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "roles" table
--
ALTER TABLE ONLY "roles"
    ADD CONSTRAINT "roles_fk_0"
    FOREIGN KEY("createdBy")
    REFERENCES "staff_users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "staff_user_permissions" table
--
ALTER TABLE ONLY "staff_user_permissions"
    ADD CONSTRAINT "staff_user_permissions_fk_0"
    FOREIGN KEY("staffUserId")
    REFERENCES "staff_users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "staff_user_permissions"
    ADD CONSTRAINT "staff_user_permissions_fk_1"
    FOREIGN KEY("permissionId")
    REFERENCES "permissions"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "staff_user_permissions"
    ADD CONSTRAINT "staff_user_permissions_fk_2"
    FOREIGN KEY("grantedBy")
    REFERENCES "staff_users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "staff_user_roles" table
--
ALTER TABLE ONLY "staff_user_roles"
    ADD CONSTRAINT "staff_user_roles_fk_0"
    FOREIGN KEY("staffUserId")
    REFERENCES "staff_users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "staff_user_roles"
    ADD CONSTRAINT "staff_user_roles_fk_1"
    FOREIGN KEY("roleId")
    REFERENCES "roles"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "staff_user_roles"
    ADD CONSTRAINT "staff_user_roles_fk_2"
    FOREIGN KEY("assignedBy")
    REFERENCES "staff_users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_log" table
--
ALTER TABLE ONLY "serverpod_log"
    ADD CONSTRAINT "serverpod_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_message_log" table
--
ALTER TABLE ONLY "serverpod_message_log"
    ADD CONSTRAINT "serverpod_message_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_query_log" table
--
ALTER TABLE ONLY "serverpod_query_log"
    ADD CONSTRAINT "serverpod_query_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR vertic_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('vertic_server', '20250622230556386', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250622230556386', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth', '20240520102713718', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240520102713718', "timestamp" = now();


COMMIT;
