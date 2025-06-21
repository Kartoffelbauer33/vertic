import 'dart:typed_data';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class DocumentManagementEndpoint extends Endpoint {
  /// Upload a new registration document (PDF)
  Future<DocumentUploadResponse> uploadDocument(
    Session session,
    String title,
    String description,
    String documentType,
    ByteData pdfData,
    String fileName,
  ) async {
    try {
      session.log(
          '🔍 Upload Request: title="$title", type="$documentType", size=${pdfData.lengthInBytes} bytes',
          level: LogLevel.info);

      // Validate PDF data
      if (pdfData.lengthInBytes == 0) {
        session.log('❌ Validation Error: PDF ist leer',
            level: LogLevel.warning);
        return DocumentUploadResponse(
          success: false,
          message: 'PDF-Datei ist leer',
          errorCode: 'EMPTY_FILE',
        );
      }

      // Check file size (max 10MB)
      const maxFileSize = 10 * 1024 * 1024; // 10MB
      if (pdfData.lengthInBytes > maxFileSize) {
        session.log(
            '❌ Validation Error: PDF zu groß (${pdfData.lengthInBytes} bytes)',
            level: LogLevel.warning);
        return DocumentUploadResponse(
          success: false,
          message: 'PDF-Datei ist zu groß (max. 10MB)',
          errorCode: 'FILE_TOO_LARGE',
        );
      }

      session.log('✅ Validation passed, creating database record...',
          level: LogLevel.info);

      // Create document record
      final document = RegistrationDocument(
        title: title.trim(),
        description: description.trim().isEmpty ? null : description.trim(),
        documentType: documentType.toLowerCase(),
        pdfData: pdfData,
        fileName: fileName,
        fileSize: pdfData.lengthInBytes,
        uploadedByStaffId: null, // TODO: Add staff authentication
        isActive: true,
        sortOrder: 1, // TODO: Calculate proper sort order
        createdAt: DateTime.now().toUtc(),
      );

      session.log('🗄️ Inserting into database...', level: LogLevel.info);
      final savedDocument = await session.db.insertRow(document);
      session.log('✅ Database insert successful: ID=${savedDocument.id}',
          level: LogLevel.info);

      session.log(
          '✅ Dokument hochgeladen: ${savedDocument.title} (${savedDocument.fileSize} bytes)',
          level: LogLevel.info);

      return DocumentUploadResponse(
        success: true,
        documentId: savedDocument.id,
        message: 'Dokument "${savedDocument.title}" erfolgreich hochgeladen',
      );
    } catch (e, stackTrace) {
      session.log('❌ Upload Error: $e', level: LogLevel.error);
      session.log('📄 StackTrace: $stackTrace', level: LogLevel.error);
      return DocumentUploadResponse(
        success: false,
        message: 'Unerwarteter Fehler beim Upload: $e',
        errorCode: 'UPLOAD_ERROR',
      );
    }
  }

  /// Get all registration documents
  Future<List<RegistrationDocument>> getAllDocuments(Session session) async {
    try {
      final documents = await session.db.find<RegistrationDocument>();

      session.log('📋 ${documents.length} Dokumente geladen',
          level: LogLevel.info);
      return documents;
    } catch (e) {
      session.log('❌ Fehler beim Laden der Dokumente: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  /// Update document status (activate/deactivate)
  Future<bool> updateDocumentStatus(
      Session session, int documentId, bool isActive) async {
    try {
      final document =
          await session.db.findById<RegistrationDocument>(documentId);
      if (document == null) {
        return false;
      }

      final updatedDocument = document.copyWith(
        isActive: isActive,
        updatedAt: DateTime.now().toUtc(),
      );

      await session.db.updateRow(updatedDocument);

      session.log(
          '✅ Dokument-Status aktualisiert: ${document.title} -> ${isActive ? "aktiv" : "inaktiv"}',
          level: LogLevel.info);
      return true;
    } catch (e) {
      session.log('❌ Fehler beim Aktualisieren des Dokument-Status: $e',
          level: LogLevel.error);
      return false;
    }
  }

  /// Download a document PDF
  Future<ByteData?> downloadDocument(Session session, int documentId) async {
    try {
      final document =
          await session.db.findById<RegistrationDocument>(documentId);
      if (document == null) {
        return null;
      }

      return document.pdfData;
    } catch (e) {
      session.log('❌ Fehler beim Download des Dokuments: $e',
          level: LogLevel.error);
      return null;
    }
  }

  /// Delete a document
  Future<bool> deleteDocument(Session session, int documentId) async {
    try {
      session.log('🗑️ Deleting document: documentId=$documentId',
          level: LogLevel.info);

      final result = await RegistrationDocument.db.deleteWhere(
        session,
        where: (d) => d.id.equals(documentId),
      );

      if (result.isNotEmpty) {
        session.log('✅ Document deleted successfully: documentId=$documentId',
            level: LogLevel.info);
        // Optional: Also delete associated rules and agreements
        await DocumentDisplayRule.db.deleteWhere(session,
            where: (r) => r.documentId.equals(documentId));
        await ClientDocumentAgreement.db.deleteWhere(session,
            where: (a) => a.documentId.equals(documentId));
        session.log('✅ Associated rules and agreements deleted.',
            level: LogLevel.info);
        return true;
      } else {
        session.log('⚠️ Document to delete not found: documentId=$documentId',
            level: LogLevel.warning);
        return false;
      }
    } catch (e, stackTrace) {
      session.log('❌ Error deleting document: $e',
          level: LogLevel.error, stackTrace: stackTrace);
      return false;
    }
  }

  /// Update document PDF content while keeping all other properties
  Future<DocumentUploadResponse> updateDocument(
    Session session,
    int documentId,
    ByteData newPdfData,
    String newFileName,
  ) async {
    try {
      session.log(
          '🔄 Updating document: documentId=$documentId, newFile="$newFileName", size=${newPdfData.lengthInBytes} bytes',
          level: LogLevel.info);

      // Validate PDF data
      if (newPdfData.lengthInBytes == 0) {
        session.log('❌ Validation Error: PDF ist leer',
            level: LogLevel.warning);
        return DocumentUploadResponse(
          success: false,
          message: 'PDF-Datei ist leer',
          errorCode: 'EMPTY_FILE',
        );
      }

      // Check file size (max 10MB)
      const maxFileSize = 10 * 1024 * 1024; // 10MB
      if (newPdfData.lengthInBytes > maxFileSize) {
        session.log(
            '❌ Validation Error: PDF zu groß (${newPdfData.lengthInBytes} bytes)',
            level: LogLevel.warning);
        return DocumentUploadResponse(
          success: false,
          message: 'PDF-Datei ist zu groß (max. 10MB)',
          errorCode: 'FILE_TOO_LARGE',
        );
      }

      // Get existing document
      final existingDocument =
          await session.db.findById<RegistrationDocument>(documentId);
      if (existingDocument == null) {
        session.log('❌ Document not found: documentId=$documentId',
            level: LogLevel.warning);
        return DocumentUploadResponse(
          success: false,
          message: 'Dokument nicht gefunden',
          errorCode: 'DOCUMENT_NOT_FOUND',
        );
      }

      session.log('✅ Existing document found, updating PDF content...',
          level: LogLevel.info);

      // Update only PDF-related fields, keep everything else unchanged
      final updatedDocument = existingDocument.copyWith(
        pdfData: newPdfData,
        fileName: newFileName,
        fileSize: newPdfData.lengthInBytes,
        updatedAt: DateTime.now().toUtc(),
      );

      final savedDocument = await session.db.updateRow(updatedDocument);
      session.log('✅ Document updated successfully: ID=${savedDocument.id}',
          level: LogLevel.info);

      session.log(
          '✅ Dokument aktualisiert: ${savedDocument.title} (${savedDocument.fileSize} bytes)',
          level: LogLevel.info);

      return DocumentUploadResponse(
        success: true,
        documentId: savedDocument.id,
        message: 'Dokument "${savedDocument.title}" erfolgreich aktualisiert',
      );
    } catch (e, stackTrace) {
      session.log('❌ Update Error: $e', level: LogLevel.error);
      session.log('📄 StackTrace: $stackTrace', level: LogLevel.error);
      return DocumentUploadResponse(
        success: false,
        message: 'Unerwarteter Fehler beim Update: $e',
        errorCode: 'UPDATE_ERROR',
      );
    }
  }

  /// Get all gyms for dropdown selection
  Future<List<Gym>> getAllGyms(Session session) async {
    try {
      session.log('🏢 Getting all gyms for selection', level: LogLevel.info);

      final gyms = await Gym.db.find(
        session,
        where: (g) => g.isActive.equals(true),
        orderBy: (g) => g.name,
      );

      session.log('📋 Found ${gyms.length} active gyms', level: LogLevel.info);
      return gyms;
    } catch (e, stackTrace) {
      session.log('❌ Error getting gyms: $e',
          level: LogLevel.error, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get display rules for a specific document
  Future<List<DocumentDisplayRule>> getDisplayRulesForDocument(
      Session session, int documentId) async {
    try {
      session.log(
          '🔍 Getting display rules for document: documentId=$documentId',
          level: LogLevel.info);

      final rules = await session.db.find<DocumentDisplayRule>();
      final documentRules =
          rules.where((r) => r.documentId == documentId).toList();

      session.log(
          '📋 Found ${documentRules.length} rules for document $documentId',
          level: LogLevel.info);
      return documentRules;
    } catch (e, stackTrace) {
      session.log('❌ Error getting display rules: $e',
          level: LogLevel.error, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Add or update a document display rule
  Future<DocumentDisplayRule> addOrUpdateDisplayRule(
      Session session, DocumentDisplayRule rule) async {
    try {
      session.log('📝 Adding/updating display rule: ${rule.toString()}',
          level: LogLevel.info);

      DocumentDisplayRule savedRule;
      if (rule.id == null) {
        // Create new rule
        final newRule = rule.copyWith(
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
        savedRule = await session.db.insertRow(newRule);
        session.log('✅ New display rule created: ID=${savedRule.id}',
            level: LogLevel.info);
      } else {
        // Update existing rule
        final updatedRule = rule.copyWith(
          updatedAt: DateTime.now().toUtc(),
        );
        savedRule = await session.db.updateRow(updatedRule);
        session.log('✅ Display rule updated: ID=${savedRule.id}',
            level: LogLevel.info);
      }

      return savedRule;
    } catch (e, stackTrace) {
      session.log('❌ Error saving display rule: $e',
          level: LogLevel.error, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Delete a document display rule
  Future<bool> deleteDisplayRule(Session session, int ruleId) async {
    try {
      session.log('🗑️ Deleting display rule: ruleId=$ruleId',
          level: LogLevel.info);

      final result = await DocumentDisplayRule.db.deleteWhere(
        session,
        where: (r) => r.id.equals(ruleId),
      );

      if (result.isNotEmpty) {
        session.log('✅ Display rule deleted: ruleId=$ruleId',
            level: LogLevel.info);
        return true;
      } else {
        session.log('⚠️ Display rule not found: ruleId=$ruleId',
            level: LogLevel.warning);
        return false;
      }
    } catch (e, stackTrace) {
      session.log('❌ Error deleting display rule: $e',
          level: LogLevel.error, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get documents applicable for a specific user (age, gym, etc.)
  Future<List<DocumentWithRules>> getDocumentsForUser(
    Session session,
    int userAge,
    int? userGymId,
  ) async {
    try {
      session.log(
          '🔍 Getting documents for user: age=$userAge, gymId=$userGymId',
          level: LogLevel.info);

      // Get all active documents
      final documents = await session.db.find<RegistrationDocument>();

      final applicableDocuments = <DocumentWithRules>[];

      for (final document in documents) {
        if (!document.isActive) continue;

        // Get rules for this document
        final rules = await session.db.find<DocumentDisplayRule>();
        final documentRules = rules
            .where((r) => r.documentId == document.id && r.isActive)
            .toList();

        // Check if document applies to user
        bool appliesToUser = false;
        bool isRequired = false;

        if (documentRules.isEmpty) {
          // No rules = applies to everyone
          appliesToUser = true;
        } else {
          for (final rule in documentRules) {
            bool ruleMatches = true;

            // Check age requirements
            if (rule.minAge != null && userAge < rule.minAge!) {
              ruleMatches = false;
            }
            if (rule.maxAge != null && userAge > rule.maxAge!) {
              ruleMatches = false;
            }

            // Check gym requirements
            if (rule.gymId != null && rule.gymId != userGymId) {
              ruleMatches = false;
            }

            if (ruleMatches) {
              appliesToUser = true;
              if (rule.isRequired) {
                isRequired = true;
              }
            }
          }
        }

        if (appliesToUser) {
          applicableDocuments.add(DocumentWithRules(
            document: document,
            rules: documentRules,
            isRequiredForUser: isRequired,
            appliesToUser: true,
          ));
        }
      }

      session.log(
          '📋 ${applicableDocuments.length} anwendbare Dokumente für Benutzer (Alter: $userAge, Gym: $userGymId)',
          level: LogLevel.info);
      return applicableDocuments;
    } catch (e, stackTrace) {
      session.log('❌ Fehler beim Laden der Benutzer-Dokumente: $e',
          level: LogLevel.error);
      session.log('📄 StackTrace: $stackTrace', level: LogLevel.error);
      rethrow;
    }
  }

  /// Record user agreement to a document
  Future<bool> recordUserAgreement(
    Session session,
    int clientId,
    int documentId,
    String? ipAddress,
    String? userAgent,
  ) async {
    try {
      session.log(
          '🔍 Recording user agreement: clientId=$clientId, documentId=$documentId',
          level: LogLevel.info);

      // Check if agreement already exists
      final agreements = await session.db.find<ClientDocumentAgreement>();
      final existingAgreement = agreements
          .where((a) => a.clientId == clientId && a.documentId == documentId)
          .firstOrNull;

      if (existingAgreement != null) {
        session.log(
            '⚠️ Agreement already exists for clientId=$clientId, documentId=$documentId',
            level: LogLevel.warning);
        return true; // Already agreed
      }

      // Create new agreement
      final agreement = ClientDocumentAgreement(
        clientId: clientId,
        documentId: documentId,
        agreedAt: DateTime.now().toUtc(),
        ipAddress: ipAddress,
        userAgent: userAgent,
        documentVersion: null, // TODO: Add versioning
        isRevoked: false,
      );

      await session.db.insertRow(agreement);

      session.log(
          '✅ User agreement recorded: clientId=$clientId, documentId=$documentId',
          level: LogLevel.info);
      return true;
    } catch (e, stackTrace) {
      session.log('❌ Fehler beim Speichern der Zustimmung: $e',
          level: LogLevel.error);
      session.log('📄 StackTrace: $stackTrace', level: LogLevel.error);
      return false;
    }
  }
}
