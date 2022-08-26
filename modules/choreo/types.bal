// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 Inc. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

type ApiProperties record {
    string name="";
    string 'version="1.0.0";
    string context="";
    string description="";
    string[] policies=[];
    json endpointConfig={};
    
};

public type ApiDetail record {
    string? apiThrottlingPolicy;
    json corsConfiguration;
    json businessInformation;
    string[] tags;
};

public type DocumentList record {
    string? summary;
    string? sourceUrl;
    string? visibility;
    string? sourceType;
    string? otherTypeName;
    string? name;
    string? documentId ="";
    string? 'type;
};

public type Documents record {
    string next;
    string previous;
    int count;
    DocumentList[] list;
};

public type DocumentDeail record {
   string documentId;
};