// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/log;
import ballerinax/salesforce as sfdc;
import ballerinax/salesforce.bulk;
import ballerina/io;

public function main() {

    string batchId = "";

    // Create Salesforce client configuration by reading from config file.
    sfdc:ConnectionConfig sfConfig = {
        baseUrl: "<BASE_URL>",
        clientConfig: {
            clientId: "<CLIENT_ID>",
            clientSecret: "<CLIENT_SECRET>",
            refreshToken: "<REFESH_TOKEN>",
            refreshUrl: "<REFRESH_URL>"
        }
    };

    // Create Salesforce client.
    bulk:Client bulkClient = checkpanic new (sfConfig);

    string xmlContactsFilePath = "resources/contacts.xml";

    bulk:BulkJob|error insertJob = bulkClient->createJob("insert", "Contact", "XML");

    if (insertJob is bulk:BulkJob) {
        io:ReadableByteChannel|io:Error rbc = io:openReadableFile(xmlContactsFilePath);
        if (rbc is io:ReadableByteChannel) {
            error|bulk:BatchInfo batch = bulkClient->addBatch(insertJob, rbc);
            if (batch is bulk:BatchInfo) {
                string message = batch.id.length() > 0 ? "Batch Added Successfully" : "Failed to add the Batch";
                batchId = batch.id;
                log:printInfo(message + " : " + message + " " + batchId);
            } else {
                log:printError(batch.message());
            }
        }
        else {
            log:printError(rbc.message());
        }

        //get job info
        error|bulk:JobInfo jobInfo = bulkClient->getJobInfo(insertJob);
        if (jobInfo is bulk:JobInfo) {
            string message = jobInfo.id.length() > 0 ? "Jon Info Received Successfully" : "Failed Retrieve Job Info";
            log:printInfo(message);
        } else {
            log:printError(jobInfo.message());
        }

        //get batch info
        error|bulk:BatchInfo batchInfo = bulkClient->getBatchInfo(insertJob, batchId);
        if (batchInfo is bulk:BatchInfo) {
            string message = batchInfo.id == batchId ? "Batch Info Received Successfully" : "Failed to Retrieve Batch Info";
            log:printInfo(message);
        } else {
            log:printError(batchInfo.message());
        }

        //get all batches
        error|bulk:BatchInfo[] batchInfoList = bulkClient->getAllBatches(insertJob);
        if (batchInfoList is bulk:BatchInfo[]) {
            string message = batchInfoList.length() == 1 ? "All Batches Received Successfully" : "Failed to Retrieve All Batches";
            log:printInfo(message);
        } else {
            log:printError(batchInfoList.message());
        }

        //get batch request
        var batchRequest = bulkClient->getBatchRequest(insertJob, batchId);
        if (batchRequest is xml) {
            string message = (batchRequest/<*>).length() > 0 ? "Batch Request Received Successfully" : "Failed to Retrieve Batch Request";
            log:printInfo(message);

        } else if (batchRequest is error) {
            log:printError(batchRequest.message());
        } else {
            log:printError(batchRequest.toString());
        }

        //get batch result
        var batchResult = bulkClient->getBatchResult(insertJob, batchId);
        if (batchResult is bulk:Result[]) {
            foreach bulk:Result res in batchResult {
                if (!res.success) {
                    log:printError("Failed result, res=" + res.toString(), err = ());
                }
            }
        } else if (batchResult is error) {
            log:printError(batchResult.message());
        } else {
            log:printError(batchResult.toString());
        }

        //close job
        error|bulk:JobInfo closedJob = bulkClient->closeJob(insertJob);
        if (closedJob is bulk:JobInfo) {
            string message = closedJob.state == "Closed" ? "Job Closed Successfully" : "Failed to Close the Job";
            log:printInfo(message);
        } else {
            log:printError(closedJob.message());
        }
    }

}