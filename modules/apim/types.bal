// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 Inc. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

type Pagination record {
    int total;
    int offset;
    int 'limit;
};

type ListItem record {
    string provider;
    string name;
    string context;
    string? description;
    string id;
    string? thumbnailUri;
    string 'version;
    string status;
};

type APIList record {
    string next;
    Pagination pagination;
    string previous;
    int count;
    ListItem[] list;
};

type SequencesItem record {
    boolean shared;
    string name;
    string? id;
    string 'type;
};

type EndpointSecurity record {
    string? 'type;
};

public type AdditionalProperties record {
};

public type APIDetail record {
    string name;
    string id;
    string? description;
    string context;
    string[]? tiers;
    SequencesItem[]? sequences;
    string endpointConfig;
    string? wsdlUri;
    string[]? accessControlRoles;
    string? visibility;
    string[]? visibleRoles;
    string? accessControl;
    EndpointSecurity? endpointSecurity;
    string? apiLevelPolicy;
    string[]? visibleTenants;
    string? authorizationHeader;
    AdditionalProperties? additionalProperties;
    string? responseCaching;
    string apiDefinition;
    json corsConfiguration;
    json businessInformation;
    string[] tags;
    json|string maxTps;
};

type Application record {
    string applicationId;
};

type ApplicationList record {
    string? next;
    string? previous;
    int count;
    Application[] list;
};

public type Token record {
    string[] tokenScopes;
};

public type KeysItem record {
    string[] supportedGrantTypes;
    Token token;
};

public type ApplicationDetails record {
    KeysItem[] keys;
};

public type APISummary record {
    string name = "";
    boolean scopes = false;
    boolean soapToREST = false;
    string endpointSecurity = "";
    boolean grants = false;
    boolean customMediation = false;
    boolean accessControl = false;
    boolean visibility = false;
    boolean authorizationHeader = false;
    boolean additionalProperties = false;
    boolean responseCaching = false;
    boolean throttlingPolicy = false;
    boolean customThrottlingPolicy = false;
    string endpoint_type = "";
    boolean maxTps = false;
};

public type SwaggerDef record {

    json? x\-wso2\-security;

};

public type EndpointConfig record {
    string endpoint_type;
};
