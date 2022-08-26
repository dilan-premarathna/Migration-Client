// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 Inc. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/mime;
import ballerina/regex;
import migration_client.apim;

string documentName = "";
configurable string cloudOrgName = ?;
http:Client graphQL = check new (graphQLEP);
http:Client choreoPublisherClient = check new (publisherOpenAPIEP);
http:Client publisherAPIClient = check new (publisherAPIEP, {http1Settings: {chunking: http:CHUNKING_NEVER}});

# Description
#
# + apiDetail - Details of the API obtained from API Cloud
# + return - If failed returns error 
public function createAPI(apim:APIDetail apiDetail) returns error? {
    log:printInfo("Creating API", apiName = apiDetail.name, cloudAPIID = apiDetail.id);
    error? swaggerDef = getSwaggerDef(apiDetail);
    if swaggerDef is error {
        log:printError("Error occured while getting api def", 'error = swaggerDef);
    }
    string[] context = regex:split(apiDetail.context, cloudOrgName);
    string apiContext = context[context.length() - 1];

    http:Request req = new ();
    ApiProperties apiPropery = {};
    apiPropery.name = apiDetail.name;
    apiPropery.context = contextPrefix + apiContext;
    apiPropery.description = apiDetail.description ?: "";
    apiPropery.policies = apiDetail.tiers ?: [];
    apiPropery.endpointConfig = check apiDetail.endpointConfig.fromJsonString();

    mime:Entity jsonFilePart = new;
    jsonFilePart.setContentDisposition(getContentDispositionForFormData("file", "swagger.json"));
    jsonFilePart.setFileAsEntityBody(filePath);

    mime:Entity jsonBodyPart = new;
    jsonBodyPart.setContentDisposition(
                        getContentDispositionForFormData("additionalProperties", ""));
    jsonBodyPart.setJson(apiPropery.toJson());

    mime:Entity[] bodyParts = [jsonFilePart, jsonBodyPart];
    req.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);
    http:Response createProxy = check choreoPublisherClient->post("", req, {"Authorization": "Bearer " + token});
    json|http:ClientError chreoAPIDetail = createProxy.getJsonPayload();

    string choreoApiID = "";
    if chreoAPIDetail is json {
        if createProxy.statusCode != 201 {
            log:printError("API Proxy Creation Failure", responseStatusCode = createProxy.statusCode, responsePayload = chreoAPIDetail, CloudAPIID = apiDetail.id, apiDetail = chreoAPIDetail);
            return error("API Proxy Creation Failure");
        }
        choreoApiID = check chreoAPIDetail.id;
        log:printInfo("API Creations status", responseStatusCode = createProxy.statusCode, CloudAPIID = apiDetail.id, ChoreoAPIID = choreoApiID, apiDetail = chreoAPIDetail);
        string name = apiDetail.name;
        string apiName = name.toLowerAscii().trim();
        string graphQLQuery = string `mutation{ createComponent(component: {name: "${apiName}",orgId: ${orgId},orgHandler: "${orgHandler}",displayName: "${name}",displayType: "proxy",projectId: "${projectId}",labels: "",version: "1.0.0",description: "",apiId: "${choreoApiID}",ballerinaVersion: "${ballerinaVersion}",triggerChannels: "",triggerID: null,httpBase: true,sampleTemplate: "",accessibility: "external",repositorySubPath: "",repositoryType: "",repositoryBranch: "",}){id, orgId, projectId, handler}}`;
        http:Response|error createComponent = graphQL->post("", {"query": graphQLQuery}, {"Authorization": "Bearer " + token});
        if createComponent is error {
            log:printError("Error creating Component", CloudAPIID = apiDetail.id, 'error = createComponent);
            return createComponent;
        }

    } else {
        log:printError("Error creating API", CloudAPIID = apiDetail.id, 'error = chreoAPIDetail);
        return chreoAPIDetail;

    }

    error? updateAPIResult = updateAPI(apiDetail, choreoApiID);
    if updateAPIResult is error {
        log:printError("Error in update API", updateAPIResult);
    }
}

function getSwaggerDef(apim:APIDetail apiDetail) returns error? {

    filePath = "./resources/" + apiDetail.id + "/swagger.json";
    check io:fileWriteJson(filePath, check apiDetail.apiDefinition.fromJsonString());
    log:printInfo("The swagger file created successfully.");

}

function getContentDispositionForFormData(string partName, string fileName)
                                    returns (mime:ContentDisposition) {
    mime:ContentDisposition contentDisposition = new;
    contentDisposition.name = partName;
    contentDisposition.disposition = "form-data";
    if partName == "file" {
        contentDisposition.fileName = fileName;
    }

    return contentDisposition;
}

function updateAPI(apim:APIDetail cloudAPIDetails, string choreoApiID) returns error? {

    string path = choreoApiID + "?organizationId=" + orgUUId;
    ApiDetail choreoAPIDetails = check publisherAPIClient->get(path, {"Authorization": "Bearer " + token});

    choreoAPIDetails.apiThrottlingPolicy = cloudAPIDetails.apiLevelPolicy;
    choreoAPIDetails.corsConfiguration = cloudAPIDetails.corsConfiguration;
    choreoAPIDetails.businessInformation = cloudAPIDetails.businessInformation;
    choreoAPIDetails.tags = cloudAPIDetails.tags;

    ApiDetail|error choreoAPIUpdate = publisherAPIClient->put(path, choreoAPIDetails, {"Authorization": "Bearer " + token});
    if choreoAPIUpdate is error {
        log:printError("Error in updating API", cloudAPIID = choreoAPIDetails, choreoApiID = choreoApiID, 'error = choreoAPIUpdate);
        return choreoAPIUpdate;
    }
    error? document = updateDocument(cloudAPIDetails.id, choreoApiID);
    if document is error {
        log:printError("Error in updating document", cloudAPIID = choreoAPIDetails, choreoApiID = choreoApiID, 'error = document);
        return document;
    }

}

function updateDocument(string cloudApiID, string choreoApiID) returns error? {

    string path = cloudApiID + "/documents";
    Documents documentList = check apim:apiDetailClient->get(path);
    log:printInfo("Api Cloud Document List ", documentLIst = documentList, cloudApiID = cloudApiID, choreoApiID = choreoApiID);
    if documentList.list != [] {
        foreach DocumentList item in documentList.list {
            DocumentDeail dock = check publisherAPIClient->post(choreoApiID + "/documents" + "?organizationId=" + orgUUId, item, {"Authorization": "Bearer " + token});
            log:printInfo("Document Content is ", docContent = item.sourceType.toString());
            if item.sourceType == "FILE" && dock.documentId is string {
                string|error docPath = getDocument(cloudApiID, <string>item.documentId);
                log:printInfo("Document has File Content");
                if docPath is string {
                    error? uploadDocumentResult = uploadDocument(docPath, choreoApiID, dock.documentId);
                    if uploadDocumentResult is error {
                        log:printError("Error in uploadDocument Result", 'error = uploadDocumentResult);
                    }
                } else {
                    log:printError("Error in document upload", 'error = docPath);
                }

            } else if item.sourceType == "INLINE" {
                string|error inlineContent = getInlineContent(cloudApiID, <string>item.documentId);
                if inlineContent is string {
                    log:printInfo("Document has inline Content");
                    error? upload = uploadInlineContent(inlineContent, choreoApiID, dock.documentId);
                    if upload is error {
                        log:printError("Error in uploading inline content", cloudApiID = cloudApiID, 'error = upload);
                    }
                } else {
                    log:printError("Error in getting inline content", 'error = inlineContent);
                }
            }
        }
    }
}

function getDocument(string apiID, string docId) returns error|string {
    string fileLocation = "";
    http:Response|error document = check apim:apiDetailClient->get(apiID + "/documents/" + docId + "/content");

    if (document is http:Response) {

        string|http:HeaderNotFoundError headers = document.getHeader("Content-Disposition");
        string[] names = [];
        if headers is string {
            names = regex:split(headers, "filename=\"");
            documentName = regex:replace(names[1], "\"", "");
            byte[]|http:ClientError binaryPayload = document.getBinaryPayload();
            fileLocation = resourcePath + apiID + "/" + documentName;
            if binaryPayload is byte[] {
                check io:fileWriteBytes(fileLocation, binaryPayload);
            } else {
                log:printError("Document does not have binary content", cloudAPIID = apiID, cloudDocId = docId, 'error = binaryPayload);
            }
        } else {
            log:printError("Response does not have required content", cloudAPIID = apiID, cloudDocId = docId, 'error = headers);
            return headers;
        }

    } else {
        log:printError("Error in retriving document from API Cloud", CloudAPIID = apiID, CloudDocID = docId, 'error = document);
        return document;
    }
    return fileLocation;
}

function uploadDocument(string filePath, string apiID, string docID) returns error? {

    http:Request req = new ();
    mime:Entity documentFilePart = new;
    log:printInfo("Uploading document", documentName = documentName, choreoAPIID = apiID, choreoDocID = docID);
    documentFilePart.setContentDisposition(getContentDispositionForFormData("file", documentName));
    documentFilePart.setFileAsEntityBody(filePath);
    mime:Entity[] bodyParts = [documentFilePart];
    req.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);
    json response = check publisherAPIClient->post(apiID + "/documents/" + docID + "/content?organizationId=" + orgUUId, req, {"Authorization": "Bearer " + token});

}

function getInlineContent(string cloudApiID, string cloudDocId) returns error|string {
    string|error document = check apim:apiDetailClient->get(cloudApiID + "/documents/" + cloudDocId + "/content");
    return document;
}

function uploadInlineContent(string content, string choreoApiId, string choreoDocId) returns error? {
    http:Request req = new ();
    mime:Entity documentInlinePart = new;
    log:printInfo("Uploading inline content", choreoAPIID = choreoApiId, choreoDocID = choreoDocId);
    documentInlinePart.setContentDisposition(getContentDispositionForFormData("inlineContent", ""));
    documentInlinePart.setText(content);
    mime:Entity[] bodyParts = [documentInlinePart];
    req.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);
    json response = check publisherAPIClient->post(choreoApiId + "/documents/" + choreoDocId + "/content?organizationId=" + orgUUId, req, {"Authorization": "Bearer " + token});

}
