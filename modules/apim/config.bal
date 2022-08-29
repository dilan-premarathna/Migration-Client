// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 Inc. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import ballerina/http;

final string apimHost = "https://gateway.api.cloud.wso2.com";
final string apiSubscriptionEP = apimHost + "/api/am/store/subscriptions?apiId=";
final string applicationDetailEP = apimHost + "/api/am/store/applications/";
final string publisherRESTEP = apimHost + "/api/am/publisher";
public string apiDetailEP = apimHost + "/api/am/publisher/apis/";
public string[] choreoThrottlingTiers = ["10KPerMin", "20KPerMin", "50KPerMin", "Unlimited", "null"];
public http:ClientConfiguration clientEPConfig = {
    auth: {
        tokenUrl: "https://gateway.api.cloud.wso2.com/token",
        clientId: clientId,
        clientSecret: clientSecret,
        scopes: ["apim:api_view", "apim:subscribe"]
    },
    secureSocket: {
        enable: false
    }
};

configurable string clientId = ?;
configurable string clientSecret = ?;
public configurable string cloudOrgName = ?;
public configurable MigrationCondition migrationCondition = ?;
