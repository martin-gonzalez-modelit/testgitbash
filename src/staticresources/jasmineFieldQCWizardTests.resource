/**
 * This test suite contains specs for c:FieldQCHomeownerUnavailableCmp, which use the Lightning Data Service (LDS)
 * <https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/data_service.htm>
 *
 * @author Gabriela Rojas <gabriela.rojas@modelit.xyz>
 * @since 2018-08
 */
describe('Field QC Wizard Upload File component', function(){

    afterEach(function() {
        // Each spec (test) renders its components into the same div, so we need to clear that div out at the end of 
        // each spec.
        $T.clearRenderedTestComponents();
    });

    /**
     * Component under test: 'c:AttachmentUploadCmp':
     * This spec creates a component, adds it to the body, waits for the rendering to complete,
     * and then ensures that the expected content has been added to the DOM.
     * NOTE: The spec and the component under test are in same locker (same namespace),
     *       so the spec is able to see the DOM owned by the component.
     */
    describe('c:AttachmentUploadCmp', function() {
        let attributes = {
            parentId: 'a0d18000004T9d5',
			appFileId: 'a0b18000001DZyj',
			filesErrorMessage: '',
			disabledButtons: false,
			totalUploadedFiles: 0,
            runningTests: true
        }

        /**
         * 
         */
        it('Verifies validation appeared when trying to upload a not image file.', function(done) {
            $T.createComponent("c:AttachmentUploadCmp", attributes, true).then(function(component) {
                var files = [];
                var filesToUpload = [];
                var len = 3;

                for (var i = 0; i < len; i++) {
                    filesToUpload[i] = new File(["foo"], "foo.txt", {type: "text/plain",});
                }
                files.push(filesToUpload);

				component.set("v.fileToBeUploaded", files);
                component.uploadFiles();
                // Verify that we get an error extension for the file.
                expect(component.get("v.filesErrorMessage")).toBe("File extension is not allowed: 'txt'");
                // End this spec successfully.
                done();
            }).catch(function(e) {
                // End this spec as a failure.
                done.fail(e);
            });
        });

		/**
         * 
         *//*
        it('Verifies application file is upload successfully', function(done) {
            $T.createComponent("c:AttachmentUploadCmp", attributes, true).then(function(component) {
				console.log('attributos');
				console.log(attributes);
				console.log(component);
				
                var mockResponse = { 
                    getState: function () { 
                        return "SUCCESS";
                    }, 
                    getReturnValue: function () { 
                        return []; 
                    } 
                };
                spyOn($A, "enqueueAction").and.callFake(function (action) {
                    var cb = action.getCallback("SUCCESS");
                    cb.fn.apply(cb.s, [mockResponse]);
                });
				
                var files = [];
                var filesToUpload = [];
                //var len = 3;

                //for (var i = 0; i < len; i++) {
                    filesToUpload[0] = new File(["foo"], "foo.png", {type: "image/png",});
                //}
                files.push(filesToUpload);

				component.set("v.fileToBeUploaded", files);

                component.uploadFiles();
                // Verify that we get an error extension for the file.
                expect(component.get("v.filesErrorMessage")).toBe("");
                expect(component.get("v.totalUploadedFiles")).toBe(3);
                // End this spec successfully.
                done();
            }).catch(function(e) {
                // End this spec as a failure.
                done.fail(e);
            });
        });*/
    });
});