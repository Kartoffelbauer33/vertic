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
    "isStaff" boolean NOT NULL DEFAULT false,
    "isHallAdmin" boolean NOT NULL DEFAULT false,
    "isSuperUser" boolean NOT NULL DEFAULT false,
    "hallId" bigint,
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
CREATE INDEX "app_user_status_idx" ON "app_users" USING btree ("accountStatus");
CREATE INDEX "app_user_verification_code_idx" ON "app_users" USING btree ("verificationCode");
CREATE INDEX "app_user_hall_idx" ON "app_users" USING btree ("hallId");
CREATE INDEX "app_user_blocked_idx" ON "app_users" USING btree ("isBlocked");
CREATE INDEX "app_user_manual_approval_idx" ON "app_users" USING btree ("isManuallyApproved");
CREATE INDEX "app_user_minor_idx" ON "app_users" USING btree ("isMinor");
CREATE INDEX "app_user_created_idx" ON "app_users" USING btree ("createdAt");
CREATE INDEX "app_user_primary_status_idx" ON "app_users" USING btree ("primaryStatusId");

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
-- Class Gym as table gyms
--
CREATE TABLE "gyms" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "shortCode" text NOT NULL,
    "city" text NOT NULL,
    "address" text,
    "description" text,
    "isActive" boolean NOT NULL DEFAULT true,
    "isVerticLocation" boolean NOT NULL DEFAULT true,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "gym_short_code_unique_idx" ON "gyms" USING btree ("shortCode");
CREATE INDEX "gym_name_idx" ON "gyms" USING btree ("name");

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
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "ticket_user_idx" ON "tickets" USING btree ("userId");
CREATE INDEX "ticket_type_idx" ON "tickets" USING btree ("ticketTypeId");
CREATE INDEX "ticket_expiry_idx" ON "tickets" USING btree ("expiryDate");
CREATE INDEX "subscription_status_idx" ON "tickets" USING btree ("subscriptionStatus");
CREATE INDEX "next_billing_date_idx" ON "tickets" USING btree ("nextBillingDate");

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
    "unlockExpiry" timestamp without time zone,
    "requiresUnlock" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "user_identity_user_idx" ON "user_identities" USING btree ("userId");
CREATE INDEX "user_identity_active_idx" ON "user_identities" USING btree ("isActive");

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
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250605141907388', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250605141907388', "timestamp" = now();

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
