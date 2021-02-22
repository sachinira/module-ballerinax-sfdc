import ballerina/config;
import ballerina/log;
import ballerinax/sfdc;

public function main(){

    string batchId = "";

    // Create Salesforce client configuration by reading from config file.
    sfdc:SalesforceConfiguration sfConfig = {
        baseUrl: config:getAsString("EP_URL"),
        clientConfig: {
            accessToken: config:getAsString("ACCESS_TOKEN"),
            refreshConfig: {
                clientId: config:getAsString("CLIENT_ID"),
                clientSecret: config:getAsString("CLIENT_SECRET"),
                refreshToken: config:getAsString("REFRESH_TOKEN"),
                refreshUrl: config:getAsString("REFRESH_URL")
            }
        }
    };

    // Create Salesforce client.
    sfdc:BaseClient baseClient = new(sfConfig);

    xml contacts = xml `<sObjects xmlns="http://www.force.com/2009/06/asyncapi/dataload">
        <sObject>
            <description>Created_from_Ballerina_Sf_Bulk_API</description>
            <Id>0032w00000QD4G2AAL</Id>
            <FirstName>Wanda</FirstName>
            <LastName>Davidson</LastName>
            <Title>Sofware Engineer Level 3</Title>
            <Phone>0991161283</Phone>
            <Email>wanda67@yahoo.com</Email>
            <My_External_Id__c>864</My_External_Id__c>
        </sObject>
        <sObject>
            <description>Created_from_Ballerina_Sf_Bulk_API</description>
            <Id>0032w00000QD4G3AAL</Id>
            <FirstName>Natasha</FirstName>
            <LastName>Romenoff</LastName>
            <Title>Software Engineer Level 3</Title>
            <Phone>0867556843</Phone>
            <Email>natashaRom@gmail.com</Email>
            <My_External_Id__c>865</My_External_Id__c>
        </sObject>
    </sObjects>`;
    

    sfdc:BulkJob|error updateJob = baseClient->creatJob("update", "Contact", "XML");

    if (updateJob is sfdc:BulkJob){
        error|sfdc:BatchInfo batch = updateJob->addBatch(contacts);
        if (batch is sfdc:BatchInfo) {
           string message = batch.id.length() > 0 ? "Batch Updated Successfully" :"Failed to Update the Batch";
           batchId = batch.id;
           log:print(message);
        } else {
           log:printError(batch.message());
        }

        //close job
        error|sfdc:JobInfo closedJob = baseClient->closeJob(updateJob);
        if (closedJob is sfdc:JobInfo) {
            string message = closedJob.state == "Closed" ? "Job Closed Successfully" :"Failed to Close the Job";
            log:print(message);
        } else {
            log:printError(closedJob.message());
        }
    }

}




