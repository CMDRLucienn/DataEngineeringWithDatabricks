-- Databricks notebook source
-- MAGIC %md-sandbox
-- MAGIC
-- MAGIC <div style="text-align: center; line-height: 0; padding-top: 9px;">
-- MAGIC   <img src="https://databricks.com/wp-content/uploads/2018/03/db-academy-rgb-1200px.png" alt="Databricks Learning" style="width: 600px">
-- MAGIC </div>

-- COMMAND ----------

-- MAGIC %md <i18n value="ba5cb184-9677-4b79-b000-f42c5fff9044"/>
-- MAGIC
-- MAGIC
-- MAGIC # Extracting Data Directly from Files
-- MAGIC
-- MAGIC In this notebook, you'll learn to extract data directly from files using Spark SQL on Databricks.
-- MAGIC
-- MAGIC A number of file formats support this option, but it is most useful for self-describing data formats (such as parquet and JSON).
-- MAGIC
-- MAGIC ## Learning Objectives
-- MAGIC By the end of this lesson, you should be able to:
-- MAGIC - Use Spark SQL to directly query data files
-- MAGIC - Leverage **`text`** and **`binaryFile`** methods to review raw file contents

-- COMMAND ----------

-- MAGIC %md <i18n value="e9800a3a-c96c-4ce2-a835-b5f058e26ead"/>
-- MAGIC
-- MAGIC
-- MAGIC ## Run Setup
-- MAGIC
-- MAGIC The setup script will create the data and declare necessary values for the rest of this notebook to execute.

-- COMMAND ----------

-- MAGIC %run ../Includes/Classroom-Setup-04.1

-- COMMAND ----------

-- MAGIC %md <i18n value="fedca70d-2bf7-415b-8ab9-1691c2366b24"/>
-- MAGIC
-- MAGIC
-- MAGIC ## Data Overview
-- MAGIC
-- MAGIC In this example, we'll work with a sample of raw Kafka data written as JSON files. 
-- MAGIC
-- MAGIC Each file contains all records consumed during a 5-second interval, stored with the full Kafka schema as a multiple-record JSON file.
-- MAGIC
-- MAGIC | field | type | description |
-- MAGIC | --- | --- | --- |
-- MAGIC | key | BINARY | The **`user_id`** field is used as the key; this is a unique alphanumeric field that corresponds to session/cookie information |
-- MAGIC | value | BINARY | This is the full data payload (to be discussed later), sent as JSON |
-- MAGIC | topic | STRING | While the Kafka service hosts multiple topics, only those records from the **`clickstream`** topic are included here |
-- MAGIC | partition | INTEGER | Our current Kafka implementation uses only 2 partitions (0 and 1) |
-- MAGIC | offset | LONG | This is a unique value, monotonically increasing for each partition |
-- MAGIC | timestamp | LONG | This timestamp is recorded as milliseconds since epoch, and represents the time at which the producer appends a record to a partition |

-- COMMAND ----------

-- MAGIC %md <i18n value="00f263ec-293b-4adf-bf4b-b81f04de6e31"/>
-- MAGIC
-- MAGIC
-- MAGIC Note that our source directory contains many JSON files.

-- COMMAND ----------

-- MAGIC %python
-- MAGIC print(DA.paths.kafka_events)
-- MAGIC
-- MAGIC files = dbutils.fs.ls(DA.paths.kafka_events)
-- MAGIC display(files)

-- COMMAND ----------

-- MAGIC %md <i18n value="f4cbde61-2f10-4758-82ca-786e16606d60"/>
-- MAGIC
-- MAGIC
-- MAGIC Here, we'll be using relative file paths to data that's been written to the DBFS root. 
-- MAGIC
-- MAGIC Most workflows will require users to access data from external cloud storage locations. 
-- MAGIC
-- MAGIC In most companies, a workspace administrator will be responsible for configuring access to these storage locations.
-- MAGIC
-- MAGIC Instructions for configuring and accessing these locations can be found in the cloud-vendor specific self-paced courses titled "Cloud Architecture & Systems Integrations".

-- COMMAND ----------

-- MAGIC %md <i18n value="8e04a0d2-4d79-4547-b2b2-765eefaf6285"/>
-- MAGIC
-- MAGIC
-- MAGIC ## Query a Single File
-- MAGIC
-- MAGIC To query the data contained in a single file, execute the query with the following pattern:
-- MAGIC
-- MAGIC <strong><code>SELECT * FROM file_format.&#x60;/path/to/file&#x60;</code></strong>
-- MAGIC
-- MAGIC Make special note of the use of back-ticks (not single quotes) around the path.

-- COMMAND ----------

SELECT * FROM json.`${DA.paths.kafka_events}/001.json`

-- COMMAND ----------

-- MAGIC %md <i18n value="02c296c6-80be-4bd8-99cc-29f2e44e1d2d"/>
-- MAGIC
-- MAGIC
-- MAGIC Note that our preview displays all 321 rows of our source file.

-- COMMAND ----------

-- MAGIC %md <i18n value="01cd5a22-a236-4ef6-bf65-7c40379d7ef9"/>
-- MAGIC
-- MAGIC
-- MAGIC ## Query a Directory of Files
-- MAGIC
-- MAGIC Assuming all of the files in a directory have the same format and schema, all files can be queried simultaneously by specifying the directory path rather than an individual file.

-- COMMAND ----------

SELECT * FROM json.`${DA.paths.kafka_events}`

-- COMMAND ----------

-- MAGIC %md <i18n value="f36c3a77-4b84-41a0-95ae-a8f999a0f60e"/>
-- MAGIC
-- MAGIC
-- MAGIC By default, this query will only show the first 1000 rows.

-- COMMAND ----------

-- MAGIC %md <i18n value="46590bb8-cf4b-4c3d-a9c6-e431bad4a5e9"/>
-- MAGIC
-- MAGIC
-- MAGIC ## Create References to Files
-- MAGIC This ability to directly query files and directories means that additional Spark logic can be chained to queries against files.
-- MAGIC
-- MAGIC When we create a view from a query against a path, we can reference this view in later queries. Here, we'll create a temporary view, but you can also create a permanent reference with regular view.

-- COMMAND ----------

CREATE OR REPLACE TEMP VIEW events_temp_view
AS SELECT * FROM json.`${DA.paths.kafka_events}`;

SELECT * FROM events_temp_view

-- COMMAND ----------

-- MAGIC %md <i18n value="0a627f4b-ec2c-4002-bf9b-07a788956f03"/>
-- MAGIC
-- MAGIC
-- MAGIC ## Extract Text Files as Raw Strings
-- MAGIC
-- MAGIC When working with text-based files (which include JSON, CSV, TSV, and TXT formats), you can use the **`text`** format to load each line of the file as a row with one string column named **`value`**. This can be useful when data sources are prone to corruption and custom text parsing functions will be used to extract value from text fields.

-- COMMAND ----------

SELECT * FROM text.`${DA.paths.kafka_events}`

-- COMMAND ----------

-- MAGIC %md <i18n value="ffae0f7a-b956-431d-b1cb-6d2be33b4f6c"/>
-- MAGIC
-- MAGIC
-- MAGIC ## Extract the Raw Bytes and Metadata of a File
-- MAGIC
-- MAGIC Some workflows may require working with entire files, such as when dealing with images or unstructured data. Using **`binaryFile`** to query a directory will provide file metadata alongside the binary representation of the file contents.
-- MAGIC
-- MAGIC Specifically, the fields created will indicate the **`path`**, **`modificationTime`**, **`length`**, and **`content`**.

-- COMMAND ----------

SELECT * FROM binaryFile.`${DA.paths.kafka_events}`

-- COMMAND ----------

-- MAGIC %md <i18n value="fa8fcc72-31c0-4825-ae6f-bf194d715f14"/>
-- MAGIC
-- MAGIC  
-- MAGIC Run the following cell to delete the tables and files associated with this lesson.

-- COMMAND ----------

-- MAGIC %python 
-- MAGIC DA.cleanup()

-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC &copy; 2022 Databricks, Inc. All rights reserved.<br/>
-- MAGIC Apache, Apache Spark, Spark and the Spark logo are trademarks of the <a href="https://www.apache.org/">Apache Software Foundation</a>.<br/>
-- MAGIC <br/>
-- MAGIC <a href="https://databricks.com/privacy-policy">Privacy Policy</a> | <a href="https://databricks.com/terms-of-use">Terms of Use</a> | <a href="https://help.databricks.com/">Support</a>
