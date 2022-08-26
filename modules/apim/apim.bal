// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 Inc. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import ballerina/http;
import ballerina/log;
import ballerina/regex;
import migration_client.util;

int apiCount = 0;
int supportedCount = 0;
map<APIDetail> APIDetailSummary = {};
final http:Client applicationListClient = check new (apiSubscriptionEP, clientEPConfig);
final http:Client apiListClient = check new (publisherRESTEP, clientEPConfig);
public final http:Client apiDetailClient = check new (apiDetailEP, clientEPConfig);
final http:Client applicationDetailClient = check new (applicationDetailEP, clientEPConfig);

# Create a summary of the Cloud APIs
# + return - Returns summary of all the migratable APIs or error
public function getAPISummary() returns map<APIDetail>|error {

    string[]|error apiList = getAPIList();

    if apiList is string[] {
        apiCount = apiList.length();
        foreach string apiId in apiList {
            boolean isMigratable = true;
            APISummary apiSummary = {};
            string[] grants = [];
            string[] scopes = [];
            log:printInfo("Analyzing the API", APIID = apiId);
            APIDetail|error apiDetail = getApiDetails(apiId);

            if apiDetail is APIDetail {
                log:printInfo("API Details", APIID = apiId, APIName = apiDetail.name, apiDetail = apiDetail);
                apiSummary.name = apiDetail.name;
                if apiDetail.sequences != [] {
                    apiSummary.customMediation = true;
                    isMigratable = false;
                }
                if apiDetail.wsdlUri != "" && apiDetail.wsdlUri != null {
                    apiSummary.soapToREST = true;
                    isMigratable = false;
                }
                json endpointSecurity = (apiDetail.endpointSecurity ?: "").toJson();
                if endpointSecurity is json && endpointSecurity != "" {
                    json|error epSecurityType = endpointSecurity.'type;

                    if epSecurityType is json {
                        apiSummary.endpointSecurity = epSecurityType.toString();
                    } else {
                        log:printError("Error occured in getting Endpoint security", 'error = epSecurityType, endpointSecurity = endpointSecurity);
                    }
                    isMigratable = false;
                }
                if apiDetail.authorizationHeader != "" && apiDetail.authorizationHeader != null {
                    apiSummary.authorizationHeader = true;
                    isMigratable = false;
                }
                if apiDetail.accessControl != "" && apiDetail.accessControl != "NONE" {
                    apiSummary.accessControl = true;
                    isMigratable = false;
                }
                if apiDetail.additionalProperties != null && apiDetail.additionalProperties != {} {
                    apiSummary.additionalProperties = true;
                    isMigratable = false;
                }
                if apiDetail.responseCaching != "" && apiDetail.responseCaching != "Disabled" {
                    apiSummary.responseCaching = true;
                    isMigratable = false;
                }
                if apiDetail.visibility != "" && apiDetail.visibility != "PUBLIC" {
                    apiSummary.visibility = true;
                    isMigratable = false;
                }
                if apiDetail.maxTps != "" && apiDetail.maxTps != null {
                    apiSummary.maxTps = true;
                    isMigratable = false;
                }
                SwaggerDef|error swaggerDefinition = (check apiDetail.apiDefinition.fromJsonString()).cloneWithType(SwaggerDef);

                if swaggerDefinition is SwaggerDef {
                    if (swaggerDefinition.x\-wso2\-security != null && swaggerDefinition.x\-wso2\-security != "") {
                        isMigratable = false;
                        apiSummary.scopes = true;
                    }
                }
                json swaggerDef = check apiDetail.apiDefinition.fromJsonString();
                string apiPolicy = apiDetail.apiLevelPolicy ?: "null";
                if checkThrottligTiers(swaggerDef, apiPolicy) {
                    apiSummary.customThrottlingPolicy = true;
                    isMigratable = false;
                }
                EndpointConfig|error endpointConfig = (check apiDetail.endpointConfig.fromJsonString()).cloneWithType(EndpointConfig);
                if endpointConfig is EndpointConfig {
                    apiSummary.endpoint_type = endpointConfig.endpoint_type;
                    if endpointConfig.endpoint_type != "http" {
                        isMigratable = false;
                    }
                }

            } else {
                log:printError("Failure in getting details of API ", APIID = apiId, 'error = apiDetail);
                continue;
            }

            string[]|error applicationList = getSubscriptionDetails(apiId);

            if (applicationList is string[]) {
                foreach var item in applicationList {
                    [grants, scopes] = getApplicationDetail(apiId, item, grants, scopes);
                }

            } else {
                log:printError("Failure in getting application list of API ", APIID = apiId, 'error = applicationList);
            }

            foreach var item in grants {
                if item != "" {
                    if (item != "client_credentials" && item != "refresh_token") {
                        apiSummary.grants = true;
                        isMigratable = false;
                    }
                }

            }

            if isMigratable {
                supportedCount += 1;
            }

            error? saveApiSummary = util:saveApiSummary([
                [
                    apiSummary.name,
                    apiSummary.scopes.toString(),
                    apiSummary.soapToREST.toString(),
                    apiSummary.endpointSecurity,
                    regex:replaceAll(grants.toString(), ",", "'"),
                    apiSummary.customMediation.toString(),
                    apiSummary.authorizationHeader.toString(),
                    apiSummary.accessControl.toString(),
                    apiSummary.additionalProperties.toString(),
                    apiSummary.responseCaching.toString(),
                    apiSummary.visibility.toString(),
                    apiSummary.throttlingPolicy.toString(),
                    apiSummary.endpoint_type.toString(),
                    apiSummary.maxTps.toString(),
                    isMigratable.toString()
                ]
            ]);

            if saveApiSummary is error {
                log:printError("Failure in writing sumery of Api", APIID = apiId, 'error = saveApiSummary);
            }
            error? saveMigrationSummary = util:saveMigrationSummary({"Total API Count": apiCount, "Migration Supported API Count": supportedCount});
            if saveMigrationSummary is error {
                log:printError("Failure in writing sumery of migration supported APIs", APIID = apiId, 'error = saveMigrationSummary);
            }
            if isMigratable {
                APIDetailSummary[apiId] = check apiDetail;
            }
        }
    } else {
        log:printError("Failure in getti the API list of the tenent", 'error = apiList);
        return APIDetailSummary;
    }
    return APIDetailSummary;
}

function getAPIList() returns string[]|error {
    string next = "";
    APIList resp = check apiListClient->get("/apis");
    next = resp.next;
    string[] apiList = [];
    foreach ListItem item in resp.list {
        apiList.push(item.id);
    }
    while next != "" {
        APIList nextResp = check apiListClient->get(next);
        foreach ListItem item in nextResp.list {
            apiList.push(item.id);
        }
        next = nextResp.next;
    }
    log:printInfo("API List of the organization", APIList = apiList);
    return apiList;

}

function getApiDetails(string apiID) returns APIDetail|error {

    APIDetail apiDetail = check apiDetailClient->get(apiID);
    return apiDetail;
}

function getSubscriptionDetails(string apiID) returns string[]|error {
    string[] applicationList = [];
    ApplicationList applicationListDetail = check applicationListClient->get(apiID);
    foreach Application item in applicationListDetail.list {
        applicationList.push(item.applicationId);
    }
    return applicationList;

}

function getApplicationDetail(string APIID, string applicationId, string[] grants, string[] scopes) returns [string[], string[]] {

    string[] applicationGrants = [];
    string[] applicationScopes = [];

    ApplicationDetails applicationDetail;
    do {

        applicationDetail = check applicationDetailClient->get(applicationId);
    } on fail var e {
        log:printError("Failure in getting application details", APPID = APIID, ApplicationID = applicationId, 'error = e);
    }

    foreach KeysItem item in applicationDetail.keys {
        applicationGrants = getUniqueArray(grants, item.supportedGrantTypes);
        applicationScopes = getUniqueArray(scopes, item.token.tokenScopes);
    }
    json result = {"GrantTypes": applicationGrants, "Scopes": applicationScopes};
    log:printInfo("API Scopes and Grant Types", APPID = APIID, ApplicationsSummery = result);
    return [applicationGrants, applicationScopes];

}

public function getUniqueArray(string[] initialArr, string[] inpurArr) returns string[] {

    map<()> m = {};
    foreach var i in initialArr {
        m[i] = ();
    }
    foreach var i in inpurArr {
        m[i] = ();
    }
    return m.keys();

}

function checkThrottligTiers(json swaggerDefinition, string apiLevelPolicy) returns boolean {
    if choreoThrottlingTiers.indexOf(apiLevelPolicy) == () {
        return true;
    }
    string[] throttling = regex:split(swaggerDefinition.toString(), "x-throttling-tier\":\"");
    int i = 0;
    map<()> m = {};
    string[] throttlingTiers = [];
    foreach var item in throttling {
        if i == 0 {
            i += 1;
            continue;
        }
        i += 1;
        string[] val = regex:split(item, "\"");

        m[val[0]] = ();
    }
    throttlingTiers = m.keys();
    log:printInfo("API throttling tiers", throttlingTiers = throttlingTiers);
    foreach string throttlingTier in throttlingTiers {

        if choreoThrottlingTiers.indexOf(throttlingTier) == () {
            return true;
        }
    }
    return false;
}
