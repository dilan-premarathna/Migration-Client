// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 Inc. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

configurable string orgUUId = ?;
configurable string projectIdHandler = ?;
configurable string orgHandler = ?;
configurable string orgId = ?;
configurable string projectId = ?;
configurable string ballerinaVersion = "swan-lake-alpha5";
final string contextPrefix = orgUUId + "/" + projectIdHandler;
configurable string token = ?;
public string filePath = "";
public string resourcePath = "./resources/";
public final string publisherOpenAPIEP = "https://sts.choreo.dev/api/am/publisher/v2/apis/import-openapi?organizationId=" + orgUUId + "&importScopes=false";
public final string publisherAPIEP = "https://sts.choreo.dev/api/am/publisher/v2/apis/";
public final string graphQLEP = "https://apis.choreo.dev/projects/1.0.0/graphql";
