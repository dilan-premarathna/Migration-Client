// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 Inc. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import ballerina/io;
import ballerina/log;
import migration_client.apim;
import migration_client.choreo;
import migration_client.util;

public function main() returns error? {
    _ = util:cleanDirectory();

    var setLogPath = log:setOutputFile("./summary/application.log");
    if setLogPath is log:Error {
        log:printError("Error in setLogPath", 'error = setLogPath);
    }

    log:printInfo("Migration client Starting to Analyze tenant");
    string filePath = "./summary/API-Summary.csv";
    string[][] headers = [["API Name", "Scopes", "SOAP API", "Endpoint Security", "Grants", "Custom Mediation", "Authorization Header", "Access Control", "Additional Properties", "Response Caching", "Visibility Feature", "Custom Throttling Policy", "Endpoint Type", "Max Tps", "Migration Supported"]];
    check io:fileWriteCsv(filePath, headers);
    log:printInfo("********* Start analyzing Cloud APIs *********");
    map<apim:APIDetail>|error apiSummary = apim:getAPISummary();
    log:printInfo("********* Completed analyzing Cloud APIs *********");
    if apiSummary is error {
        log:printError("Error in creating API Summery", 'error = apiSummary);
    } else {
        log:printInfo("********* Start API Migration *********");
        foreach var item in apiSummary {
            error? api = choreo:createAPI(item);
            if api is error {
                log:printError("Error creating Choreo API", 'error = api);
                continue;
            }

        }
        log:printInfo("********* API Migration Completed *********");
    }

}
