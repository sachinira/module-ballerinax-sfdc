// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/test;
import ballerina/lang.runtime;

@test:Config {
    enable: true,
    dependsOn: [insertCsv, upsertCsv]
}
function updateCsv() returns error? {
    log:printInfo("baseClient -> updateCsv");
    string batchId = "";
    string binnsID = getContactIdByName("Cuthbert", "Binns", "Professor Level 02");
    string shanesID = getContactIdByName("Burbage", "Shane", "Professor Level 02");
    string contacts = "Id,description,FirstName,LastName,Title,Phone,Email,My_External_Id__c\n" + binnsID 
        + ",Created_from_Ballerina_Sf_Bulk_API,Cuthbert,Binns,Professor Level 02,0222236677,bins98@gmail.com,845\n" 
        + shanesID + ",Created_from_Ballerina_Sf_Bulk_API,Burbage,Shane,Professor Level 02,0332211788,shane78@gmail.com,846";

    //create job
    BulkJob updateJob = check baseClient->createJob("update", "Contact", "CSV");

    //add csv content
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|BatchInfo batch = baseClient->addBatch(updateJob, contacts);
        if (batch is BatchInfo) {
            test:assertTrue(batch.id.length() > 0, msg = "Could not upload the contacts using CSV.");
            batchId = batch.id;
            break;
        } else {
            if currentRetry != maxIterations {
                log:printWarn("addBatch Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("addBatch Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batch.message());
            }
        }
    }

    //get job info
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|JobInfo jobInfo = baseClient->getJobInfo(updateJob);
        if (jobInfo is JobInfo) {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
            break;
        } else {
            if currentRetry != maxIterations {
                log:printWarn("getJobInfo Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getJobInfo Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = jobInfo.message());
            }
        }
    }

    //get batch info
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|BatchInfo batchInfo = baseClient->getBatchInfo(updateJob, batchId);
        if (batchInfo is BatchInfo) {
            test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
            break;
        } else {
            if currentRetry != maxIterations {
                log:printWarn("getBatchInfo Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getBatchInfo Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchInfo.message());
            }
        }
    }

    //get all batches
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|BatchInfo[] batchInfoList = baseClient->getAllBatches(updateJob);
        if (batchInfoList is BatchInfo[]) {
            test:assertTrue(batchInfoList.length() == 1, msg = "Getting all batches info failed.");
            break;
        } else {
            if currentRetry != maxIterations {
                log:printWarn("getAllBatches Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getAllBatches Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchInfoList.message());
            }
        }
    }

    //get batch request
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        var batchRequest = baseClient->getBatchRequest(updateJob, batchId);
        if (batchRequest is string) {
            test:assertTrue(checkCsvResult(batchRequest) == 2, msg = "Retrieving batch request failed.");
            break;
        } else if (batchRequest is error) {
            if currentRetry != maxIterations {
                log:printWarn("getBatchRequest Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getBatchRequest Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchRequest.message());
            }
        } else {
            test:assertFail(msg = "Invalid Batch Request!");
            break;
        }
    }

    foreach int currentRetry in 1 ..< maxIterations + 1 {
        var batchResult = baseClient->getBatchResult(updateJob, batchId);
        if (batchResult is Result[]) {
            test:assertTrue(batchResult.length() > 0, msg = "Retrieving batch result failed.");
            foreach Result res in batchResult {
                test:assertTrue(checkBatchResults(res), msg = res?.errors.toString());
            }
            break;
        } else if (batchResult is error) {
            if currentRetry != maxIterations {
                log:printWarn("getAllBatches Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getAllBatches Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchResult.message());
            }
        } else {
            test:assertFail("Invalid Batch Result!");
        }
        break;
    }

    //close job
    JobInfo closedJob = check baseClient->closeJob(updateJob);
    test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
}
