#!/bin/bash
export SRC_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export ROOT_DIR=${SRC_DIR%/*}
cd $ROOT_DIR

. ./starter.sh env

get_id_from_tfstate "AGENT_DATASOURCE_OCID" "starter_agent_ds" 
get_id_from_tfstate "AGENT_OCID" "starter_agent" 
get_id_from_tfstate "AGENT_KB_OCID" "starter_agent_kb" 
get_id_from_tfstate "DBTOOLS_OCID" "starter_dbtools_connection" 

# Upload Sample Files
echo "-- Upload Sample Files in Bucket --------------------------------------"
oci os object bulk-upload -ns $TF_VAR_namespace -bn ${TF_VAR_prefix}-agent-bucket --src-dir sample_files --overwrite --content-type auto

# RAG - Ingestion
echo "-- Running RAG Ingestion ----------------------------------------------"
oci generative-ai-agent data-ingestion-job create --compartment-id $TF_VAR_compartment_ocid --data-source-id $AGENT_DATASOURCE_OCID

# AGENT TOOLS
## RAG-TOOL
title "Creating RAG-TOOL"
oci generative-ai-agent tool create-tool-rag-tool-config \
  --agent-id $AGENT_OCID \
  --compartment-id $TF_VAR_compartment_ocid \
  --display-name rag-tool \
  --description "Use for generic questions that other tools can not answer" \
  --tool-config-knowledge-base-configs "[{
    \"knowledgeBaseId\": \"${AGENT_KB_OCID}\"
  }]" \
  --wait-for-state SUCCEEDED --wait-for-state FAILED

## FUNCTION-TOOL
title "Creating FUNCTION-TOOL"
oci generative-ai-agent tool create-tool-function-calling-tool-config \
  --agent-id $AGENT_OCID \
  --compartment-id $TF_VAR_compartment_ocid \
  --display-name generate_architecture_diagram \
  --description "Generates architecture diagram" \
  --tool-config-function "{
    \"name\": \"generate_architecture_diagram\",
    \"description\": \"generates architecture diagram\",
    \"parameters\": {  
      \"type\":\"object\",
      \"properties\":\"{\\\"steps\\\":{\\\"type\\\":\\\"string\\\",\\\"description\\\":\\\"Description of the cloud architecture to visualize.\\\"}}\",
      \"required\":\"[\\\"steps\\\"]\",
      \"additionalProperties\":\"false\"
    }
  }" \
  --wait-for-state SUCCEEDED --wait-for-state FAILED


## SQL-TOOL
title "Creating SQL-TOOL"
oci generative-ai-agent tool create-tool-sql-tool-config \
  --agent-id $AGENT_OCID \
  --compartment-id $TF_VAR_compartment_ocid \
  --display-name sql-tool \
  --description "SQL tables with Support Agents and Tickets" \
  --tool-config-database-connection "{
    \"connectionId\": \"${DBTOOLS_OCID}\",
    \"connectionType\": \"DATABASE_TOOL_CONNECTION\"
  }" \
  --tool-config-database-schema "{
    \"inputLocationType\": \"INLINE\",
    \"content\": \"CREATE TABLE SupportAgents (\\n    AgentID NUMBER PRIMARY KEY,\\n    FirstName VARCHAR2(50) NOT NULL,\\n    LastName VARCHAR2(50) NOT NULL,\\n    Email VARCHAR2(100) UNIQUE NOT NULL,\\n    Phone VARCHAR2(20)\\n);\\n\\nCREATE TABLE Tickets (\\n    TicketID NUMBER PRIMARY KEY,\\n    CustomerID NUMBER NOT NULL,\\n    Subject VARCHAR2(200) NOT NULL,\\n    Description CLOB NOT NULL,\\n    CreatedDate DATE DEFAULT SYSTIMESTAMP NOT NULL,\\n    LastUpdatedDate DATE DEFAULT SYSTIMESTAMP NOT NULL,\\n    StatusID NUMBER NOT NULL,\\n    AssignedToAgentID NUMBER,\\n    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),\\n    FOREIGN KEY (StatusID) REFERENCES TicketStatus(StatusID),\\n    FOREIGN KEY (AssignedToAgentID) REFERENCES SupportAgents(AgentID)\\n);\"     
  }" \
  --tool-config-table-and-column-description "{
    \"inputLocationType\": \"INLINE\",
    \"content\": \"SupportAgents table\\n- Each in this table contains information about a support agent which handles support tickets\\n\\nColumns:\\nAgentID - number, a unique identifier for the support agent\\nFirstName - string, the support agent's first name\\nLastName - string, the support agent's last name\\nEmail - string, the support agent's work email\\nPhone - string, the support agent's work phone\\n\\n\\nTickets table\\n- Each record in this table contains information about an issue reported by a customer alongside information about the issue as well as the status this is issue is currently in and the support agent assigned to handle the issue.\\n\\nColumns:\\nTicketID - number, a unique identifier for the ticket\\nCustomerName - Customer Name that reported the issue\\nSubject - string, a short description of the issue\\nDescription - string, a full description of the issue, contains all of the information required to understand and address the issue\\nCreatedDate - datetime, the date and time at which the ticket was created by the customer\\nLastUpdatedDate - datetime, the date and time of the last action taken by a support agent regarding this ticket\\nStatusID - number, status of the ticket\\nAssignedToAgentID - number, a support agent ID from the SupportAgents table representing the support agent assigned to handle the ticket.\"
  }" \
  --tool-config-should-enable-sql-execution true \
  --tool-config-should-enable-self-correction true \
  --tool-config-dialect ORACLE_SQL \
  --tool-config-model-size LARGE \
  --wait-for-state SUCCEEDED --wait-for-state FAILED

title "INSTALLATION DONE"
echo
echo "Some background jobs are still running (ex: RAG Ingestion). Please wait 5 mins."
echo
echo "-----------------------------------------------------------------------"
echo "Evaluation (API)"
echo "http://${APIGW_HOSTNAME}/app/evaluate?question=What%20is%20the%20importance%20of%20Virus%20and%20Intrusion%20Detection"
echo
echo "-----------------------------------------------------------------------"
echo "APEX Builder"
echo "https://${APIGW_HOSTNAME}/ords/_/landing"
echo "  Workspace: APEX_APP"
echo "  User: APEX_APP"
echo "  Password: $TF_VAR_db_password"
echo
echo "-----------------------------------------------------------------------"
echo "AI Eval (APEX)"
echo "https://${APIGW_HOSTNAME}/ords/r/apex_app/apex_app/"
echo "  User: APEX_APP / $TF_VAR_db_password"
echo
echo "-----------------------------------------------------------------------"
echo "Chat (Streamlit)"
echo "http://${BASTION_IP}:8080/"
echo

