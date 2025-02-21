/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-20-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class FileUploadController {

    @AuraEnabled
    public static void associateFileWithRecord(Id contentDocumentId, Id recordId) {
        try {
            // Check if the ContentDocument exists
            List<ContentDocument> docs = [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId LIMIT 1];
            if (docs.isEmpty()) {
                throw new AuraHandledException('No ContentDocument found for the provided ID.');
            }

            // Check if the file is already linked to the record
            List<ContentDocumentLink> existingLinks = [
                SELECT Id FROM ContentDocumentLink 
                WHERE ContentDocumentId = :contentDocumentId 
                AND LinkedEntityId = :recordId
                LIMIT 1
            ];

            if (!existingLinks.isEmpty()) {
                System.debug('⚠️ File is already linked to the record. Skipping insert.');
                return; // Exit if the link already exists
            }

            // Create a new ContentDocumentLink if not already linked
            ContentDocumentLink link = new ContentDocumentLink();
            link.ContentDocumentId = contentDocumentId;
            link.LinkedEntityId = recordId;
            link.ShareType = 'V'; // Viewer access
            link.Visibility = 'AllUsers';

            insert link;
            System.debug('✅ File successfully linked to record.');
        } catch (Exception e) {
            System.debug('❌ Error in associateFileWithRecord: ' + e.getMessage());
            throw new AuraHandledException('Failed to associate file: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<WrapperFile> getFilesForRecord(Id recordId) {
        try {
            List<WrapperFile> filesList = new List<WrapperFile>();

            // Fetch all linked ContentDocumentLinks for the given record
            List<ContentDocumentLink> documentLinks = [
                SELECT ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :recordId
            ];

            if (documentLinks.isEmpty()) {
                return filesList; // No files linked, return empty list
            }

            // Get the associated ContentDocuments
            Set<Id> documentIds = new Set<Id>();
            for (ContentDocumentLink link : documentLinks) {
                documentIds.add(link.ContentDocumentId);
            }

            List<ContentDocument> docs = [
                SELECT Id, Title, FileExtension, LatestPublishedVersionId 
                FROM ContentDocument 
                WHERE Id IN :documentIds
            ];

            for (ContentDocument doc : docs) {
                WrapperFile file = new WrapperFile();
                file.id = doc.Id;
                file.name = doc.Title;
                file.url = '/sfc/servlet.shepherd/version/download/' + doc.LatestPublishedVersionId;
                file.isImage = (doc.FileExtension.equalsIgnoreCase('png') || 
                                doc.FileExtension.equalsIgnoreCase('jpg') || 
                                doc.FileExtension.equalsIgnoreCase('jpeg'));
                filesList.add(file);
            }

            return filesList;
        } catch (Exception e) {
            System.debug('❌ Error in getFilesForRecord: ' + e.getMessage());
            throw new AuraHandledException('Failed to fetch files: ' + e.getMessage());
        }
    }

    public class WrapperFile {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String url;
        @AuraEnabled public Boolean isImage;
    }
}