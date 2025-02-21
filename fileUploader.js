import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import associateFileWithRecord from '@salesforce/apex/FileUploadController.associateFileWithRecord';
import getFilesForRecord from '@salesforce/apex/FileUploadController.getFilesForRecord';

export default class FileUploadLWC extends LightningElement {
    @api recordId;
    uploadedFiles = [];
    filesUploaded = false;

    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg'];
    }

    connectedCallback() {
        this.loadFiles();
    }

    loadFiles() {
        getFilesForRecord({ recordId: this.recordId })
            .then(result => {
                this.uploadedFiles = result.map(file => ({
                    id: file.id,
                    name: file.name,
                    url: file.url,
                    isImage: file.isImage
                }));
                this.filesUploaded = this.uploadedFiles.length > 0;
            })
            .catch(error => {
                console.error('❌ Error fetching files:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Failed to load uploaded files.',
                        variant: 'error',
                    })
                );
            });
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;

        uploadedFiles.forEach(file => {
            console.log('📂 Uploading file with ContentDocumentId:', file.documentId);
            this.associateFileWithRecord(file.documentId, this.recordId);
        });

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: `${uploadedFiles.length} Files uploaded Successfully`,
                variant: 'success',
            })
        );

        // Reload files after upload
        this.loadFiles();
    }

    associateFileWithRecord(contentDocumentId, recordId) {
        associateFileWithRecord({ contentDocumentId: contentDocumentId, recordId: recordId })
            .then(() => {
                console.log('✅ File associated successfully');
                this.loadFiles(); // Reload files to reflect changes
            })
            .catch(error => {
                console.error('❌ Error associating file:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Failed to associate file with record.',
                        variant: 'error',
                    })
                );
            });
    }
}