// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 Inc. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import ballerina/io;
import ballerina/file;

string apiSummeryPath = "";
string logPath = "";
string migrationSummeryPath = "";

public function saveApiSummary(string[][] apiSummary) returns error? {
    string filePath = "./summary/API-Summary.csv";
    check io:fileWriteCsv(filePath, apiSummary, option = "APPEND");
}

public function saveMigrationSummary(json migrationSummary) returns error? {
    string filePath = "./summary/Migration-Summary.json";
    check io:fileWriteJson(filePath, migrationSummary);
}

public function cleanDirectory() {
    error? summeryRemove = file:remove("./summary", "RECURSIVE");
    error? resourceRemove = file:remove("./resources", "RECURSIVE");
}
