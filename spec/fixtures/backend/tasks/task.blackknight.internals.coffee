module.exports = {
  _filterS3Contents:
    inputContents: [
      {
        "Key": "Managed_Update/ASMT20160406/12021_Assessment_Update_20160406.txt.gz",
        "LastModified": "2016-08-18T01:07:12.000Z",
        "ETag": "\"e8235eeb2726aaffad5f8ca689d49d74-1\"",
        "Size": 58516,
        "StorageClass": "STANDARD"
      },
      {
        "Key": "Managed_Update/ASMT20160406/Assessment_Update_Delete_20160406.txt",
        "LastModified": "2016-08-18T01:07:14.000Z",
        "ETag": "\"a95fe3bbb1f7d3a528a7f0db7d8a6003-1\"",
        "Size": 215169,
        "StorageClass": "STANDARD"
      },
      {
        "Key": "Managed_Update/ASMT20160406/metadata_asmt.txt",
        "LastModified": "2016-08-18T01:07:16.000Z",
        "ETag": "\"9c1be3962184acfe42e6c4fea0641dc2-1\"",
        "Size": 4111,
        "StorageClass": "STANDARD"
      }
    ]
    inputConfig: {
      "action": "Update",
      "tableId": "ASMT",
      "date": "20160406",
      "startTime": 1471482558075
    }
    outputFiltered: {
      fipsMap: {"12021": true}
      "Refresh": [],
      "Update": [
        {
          "action": "Update",
          "listType": "Update",
          "date": "20160406",
          "path": "Managed_Update/ASMT20160406/",
          "fileName": "12021_Assessment_Update_20160406.txt.gz",
          "fileType": "Load",
          "startTime": 1471482558075,
          "dataType": "tax",
          "rawTableSuffix": "U_12021_20160406",
          "normalSubid": "12021",
          "indicateDeletes": false,
          "deletes": "indicated"
        }
      ],
      "Delete": [
        {
          "action": "Update",
          "listType": "Delete",
          "date": "20160406",
          "path": "Managed_Update/ASMT20160406/",
          "fileName": "Assessment_Update_Delete_20160406.txt",
          "fileType": "Delete",
          "startTime": 1471482558075,
          "dataType": "tax",
          "rawTableSuffix": "U_DELETES_20160406"
        }
      ]
    }


  getProcessInfo1:
    inputSubtask: {
      batch_id: 'some_batch_id'
    }
    inputSubtaskStartTime: 1471483858343
    awsListObjectResponses: {
      "Managed_Refresh/ASMT20160406/12099": {
        "IsTruncated": false,
        "Marker": "",
        "Contents": [],
        "Name": "rmaps-blackknight-data",
        "Prefix": "Managed_Refresh/ASMT20160406",
        "MaxKeys": 1000,
        "CommonPrefixes": []
      }
      "Managed_Update/ASMT20160406/12099": {
        "IsTruncated": false,
        "Marker": "",
        "Contents": [
          {
            "Key": "Managed_Update/ASMT20160406/12099_Assessment_Update_20160406.txt.gz",
            "LastModified": "2016-08-18T01:07:12.000Z",
            "ETag": "\"e8235eeb2726aaffad5f8ca689d49d74-1\"",
            "Size": 58516,
            "StorageClass": "STANDARD"
          }
        ],
        "Name": "rmaps-blackknight-data",
        "Prefix": "Managed_Update/ASMT20160406",
        "MaxKeys": 1000,
        "CommonPrefixes": []
      }
      "Managed_Update/SAM20160406/12099": {
        "IsTruncated": false,
        "Marker": "",
        "Contents": [
          {
            "Key": "Managed_Update/SAM20160406/12099_SAM_Update_20160406.txt.gz",
            "LastModified": "2016-08-18T01:07:20.000Z",
            "ETag": "\"bab083cb39581a4d788555b52df0c803-1\"",
            "Size": 8246,
            "StorageClass": "STANDARD"
          }
        ],
        "Name": "rmaps-blackknight-data",
        "Prefix": "Managed_Update/SAM20160406",
        "MaxKeys": 1000,
        "CommonPrefixes": []
      }
      "Managed_Refresh/Deed20160406/12099": {
        "IsTruncated": false,
        "Marker": "",
        "Contents": [],
        "Name": "rmaps-blackknight-data",
        "Prefix": "Managed_Refresh/Deed20160406",
        "MaxKeys": 1000,
        "CommonPrefixes": []
      }
      "Managed_Update/Deed20160406/12099": {
        "IsTruncated": false,
        "Marker": "",
        "Contents": [],
        "Name": "rmaps-blackknight-data",
        "Prefix": "Managed_Update/Deed20160406",
        "MaxKeys": 1000,
        "CommonPrefixes": []
      }
      "Managed_Refresh/SAM20160406/12099": {
        "IsTruncated": false,
        "Marker": "",
        "Contents": [],
        "Name": "rmaps-blackknight-data",
        "Prefix": "Managed_Refresh/SAM20160406",
        "MaxKeys": 1000,
        "CommonPrefixes": []
      }
    }
    outputProcessInfo: {
      "date": "20160406",
      "hasFiles": true,
      "startTime": 1471483858343,
      "fips": '12099',
      "deleteBatchId": 'saved_batch_id',
      "loadDeleteFiles": false,
      "Refresh": [],
      "Update": [
        {
          "action": "Update",
          "listType": "Update",
          "date": "20160406",
          "path": "Managed_Update/ASMT20160406/",
          "fileName": "12099_Assessment_Update_20160406.txt.gz",
          "fileType": "Load",
          "startTime": 1471483858343,
          "dataType": "tax",
          "rawTableSuffix": "U_12099_20160406",
          "normalSubid": "12099",
          "indicateDeletes": false,
          "deletes": "indicated"
        },
        {
          "action": "Update",
          "listType": "Update",
          "date": "20160406",
          "path": "Managed_Update/SAM20160406/",
          "fileName": "12099_SAM_Update_20160406.txt.gz",
          "fileType": "Load",
          "startTime": 1471483858343,
          "dataType": "mortgage",
          "rawTableSuffix": "U_12099_20160406",
          "normalSubid": "12099",
          "indicateDeletes": false,
          "deletes": "indicated"
        }
      ],
      "Delete": [
        {
          "action": "Refresh",
          "dataType": "tax",
          "fips_code": "12099",
          "rawDeleteBatchId": "saved_batch_id",
          "rawTableSuffix": "R_12099_20160406"
        },
        {
          "action": "Refresh",
          "dataType": "deed",
          "fips_code": "12099",
          "rawDeleteBatchId": "saved_batch_id",
          "rawTableSuffix": "R_12099_20160406"
        },
        {
          "action": "Refresh",
          "dataType": "mortgage",
          "fips_code": "12099",
          "rawDeleteBatchId": "saved_batch_id",
          "rawTableSuffix": "R_12099_20160406"
        },
        {
          "action": "Update",
          "dataType": "tax",
          "fips_code": "12099",
          "rawDeleteBatchId": "saved_batch_id",
          "rawTableSuffix": "U_12099_20160406"
        },
        {
          "action": "Update",
          "dataType": "deed",
          "fips_code": "12099",
          "rawDeleteBatchId": "saved_batch_id",
          "rawTableSuffix": "U_12099_20160406"
        },
        {
          "action": "Update",
          "dataType": "mortgage",
          "fips_code": "12099",
          "rawDeleteBatchId": "saved_batch_id",
          "rawTableSuffix": "U_12099_20160406"
        }
      ]
    }

  getProcessInfo2:
    inputSubtask: {
      batch_id: 'some_batch_id'
    }
    inputSubtaskStartTime: 1471483858343
    awsListObjectResponses: {
      "Managed_Refresh/ASMT20160406": {
        "IsTruncated": false,
        "Marker": "",
        "Contents": [
          {
            "Key": "Managed_Refresh/ASMT20160406/metadata_asmt.txt",
            "LastModified": "2016-08-18T01:07:07.000Z",
            "ETag": "\"8f02711bfe80c948b352d2fcc9035d18-1\"",
            "Size": 191,
            "StorageClass": "STANDARD"
          }
        ],
        "Name": "rmaps-blackknight-data",
        "Prefix": "Managed_Refresh/ASMT20160406",
        "MaxKeys": 1000,
        "CommonPrefixes": []
      }
      "Managed_Update/ASMT20160406": {
        "IsTruncated": false,
        "Marker": "",
        "Contents": [
          {
            "Key": "Managed_Update/ASMT20160406/12021_Assessment_Update_20160406.txt.gz",
            "LastModified": "2016-08-18T01:07:12.000Z",
            "ETag": "\"e8235eeb2726aaffad5f8ca689d49d74-1\"",
            "Size": 58516,
            "StorageClass": "STANDARD"
          },
          {
            "Key": "Managed_Update/ASMT20160406/12099_Assessment_Update_20160406.txt.gz",
            "LastModified": "2016-08-18T01:07:12.000Z",
            "ETag": "\"e8235eeb2726aaffad5f8ca689d49d74-1\"",
            "Size": 58516,
            "StorageClass": "STANDARD"
          },
          {
            "Key": "Managed_Update/ASMT20160406/Assessment_Update_Delete_20160406.txt",
            "LastModified": "2016-08-18T01:07:14.000Z",
            "ETag": "\"a95fe3bbb1f7d3a528a7f0db7d8a6003-1\"",
            "Size": 215169,
            "StorageClass": "STANDARD"
          },
          {
            "Key": "Managed_Update/ASMT20160406/metadata_asmt.txt",
            "LastModified": "2016-08-18T01:07:16.000Z",
            "ETag": "\"9c1be3962184acfe42e6c4fea0641dc2-1\"",
            "Size": 4111,
            "StorageClass": "STANDARD"
          }
        ],
        "Name": "rmaps-blackknight-data",
        "Prefix": "Managed_Update/ASMT20160406",
        "MaxKeys": 1000,
        "CommonPrefixes": []
      }
      "Managed_Update/SAM20160406": {
        "IsTruncated": false,
        "Marker": "",
        "Contents": [
          {
            "Key": "Managed_Update/SAM20160406/12021_SAM_Update_20160406.txt.gz",
            "LastModified": "2016-08-18T01:07:20.000Z",
            "ETag": "\"bab083cb39581a4d788555b52df0c803-1\"",
            "Size": 8246,
            "StorageClass": "STANDARD"
          },
          {
            "Key": "Managed_Update/SAM20160406/12099_SAM_Update_20160406.txt.gz",
            "LastModified": "2016-08-18T01:07:20.000Z",
            "ETag": "\"bab083cb39581a4d788555b52df0c803-1\"",
            "Size": 8246,
            "StorageClass": "STANDARD"
          },
          {
            "Key": "Managed_Update/SAM20160406/SAM_Update_Delete_20160406.txt",
            "LastModified": "2016-08-18T01:07:23.000Z",
            "ETag": "\"add8fe56078f1167cca0ed52a7bd9889-1\"",
            "Size": 1883,
            "StorageClass": "STANDARD"
          },
          {
            "Key": "Managed_Update/SAM20160406/metadata_SAM.txt",
            "LastModified": "2016-08-18T01:07:22.000Z",
            "ETag": "\"1a23ea9d526c5e262e482830b1f9946a-1\"",
            "Size": 2858,
            "StorageClass": "STANDARD"
          }
        ],
        "Name": "rmaps-blackknight-data",
        "Prefix": "Managed_Update/SAM20160406",
        "MaxKeys": 1000,
        "CommonPrefixes": []
      }
      "Managed_Refresh/Deed20160406": {
        "IsTruncated": false,
        "Marker": "",
        "Contents": [
          {
            "Key": "Managed_Refresh/Deed20160406/metadata_Deed.txt",
            "LastModified": "2016-08-18T01:07:08.000Z",
            "ETag": "\"f8667c459e7536a92a301e2383450c6e-1\"",
            "Size": 167,
            "StorageClass": "STANDARD"
          }
        ],
        "Name": "rmaps-blackknight-data",
        "Prefix": "Managed_Refresh/Deed20160406",
        "MaxKeys": 1000,
        "CommonPrefixes": []
      }
      "Managed_Update/Deed20160406": {
        "IsTruncated": false,
        "Marker": "",
        "Contents": [
          {
            "Key": "Managed_Update/Deed20160406/12021_Deed_Update_20160406.txt.gz",
            "LastModified": "2016-08-18T01:07:18.000Z",
            "ETag": "\"906e4b34131942d6a5879ac9aa92a024-1\"",
            "Size": 27942,
            "StorageClass": "STANDARD"
          },
          {
            "Key": "Managed_Update/Deed20160406/12088_Deed_Update_20160406.txt.gz",
            "LastModified": "2016-08-18T01:07:18.000Z",
            "ETag": "\"906e4b34131942d6a5879ac9aa92a024-1\"",
            "Size": 27942,
            "StorageClass": "STANDARD"
          },
          {
            "Key": "Managed_Update/Deed20160406/metadata_Deed.txt",
            "LastModified": "2016-08-18T01:07:19.000Z",
            "ETag": "\"f23109791db33a37f2e24577527c0681-1\"",
            "Size": 3816,
            "StorageClass": "STANDARD"
          }
        ],
        "Name": "rmaps-blackknight-data",
        "Prefix": "Managed_Update/Deed20160406",
        "MaxKeys": 1000,
        "CommonPrefixes": []
      }
      "Managed_Refresh/SAM20160406": {
        "IsTruncated": false,
        "Marker": "",
        "Contents": [
          {
            "Key": "Managed_Refresh/SAM20160406/metadata_SAM.txt",
            "LastModified": "2016-08-18T01:07:10.000Z",
            "ETag": "\"70082d316b265565d6fa47537cb302d7-1\"",
            "Size": 166,
            "StorageClass": "STANDARD"
          }
        ],
        "Name": "rmaps-blackknight-data",
        "Prefix": "Managed_Refresh/SAM20160406",
        "MaxKeys": 1000,
        "CommonPrefixes": []
      }
    }
    outputProcessInfo: {
      "date": "20160406",
      "hasFiles": true,
      "startTime": 1471483858343,
      "fips": '12021',
      "deleteBatchId": 'some_batch_id',
      "loadDeleteFiles": true,
      "fipsQueue": ["12021","12088","12099"],
      "Refresh": [],
      "Update": [
        {
          "action": "Update",
          "listType": "Update",
          "date": "20160406",
          "path": "Managed_Update/ASMT20160406/",
          "fileName": "12021_Assessment_Update_20160406.txt.gz",
          "fileType": "Load",
          "startTime": 1471483858343,
          "dataType": "tax",
          "rawTableSuffix": "U_12021_20160406",
          "normalSubid": "12021",
          "indicateDeletes": false,
          "deletes": "indicated"
        },
        {
          "action": "Update",
          "listType": "Update",
          "date": "20160406",
          "path": "Managed_Update/Deed20160406/",
          "fileName": "12021_Deed_Update_20160406.txt.gz",
          "fileType": "Load",
          "startTime": 1471483858343,
          "dataType": "deed",
          "rawTableSuffix": "U_12021_20160406",
          "normalSubid": "12021",
          "indicateDeletes": false,
          "deletes": "indicated"
        },
        {
          "action": "Update",
          "listType": "Update",
          "date": "20160406",
          "path": "Managed_Update/SAM20160406/",
          "fileName": "12021_SAM_Update_20160406.txt.gz",
          "fileType": "Load",
          "startTime": 1471483858343,
          "dataType": "mortgage",
          "rawTableSuffix": "U_12021_20160406",
          "normalSubid": "12021",
          "indicateDeletes": false,
          "deletes": "indicated"
        }
      ],
      "Delete": [
        {
          "action": "Update",
          "listType": "Delete",
          "date": "20160406",
          "path": "Managed_Update/ASMT20160406/",
          "fileName": "Assessment_Update_Delete_20160406.txt",
          "fileType": "Delete",
          "startTime": 1471483858343,
          "dataType": "tax",
          "rawTableSuffix": "U_DELETES_20160406"
        },
        {
          "action": "Update",
          "listType": "Delete",
          "date": "20160406",
          "path": "Managed_Update/SAM20160406/",
          "fileName": "SAM_Update_Delete_20160406.txt",
          "fileType": "Delete",
          "startTime": 1471483858343,
          "dataType": "mortgage",
          "rawTableSuffix": "U_DELETES_20160406"
        }
      ]
    }

  getProcessInfo3:
    inputSubtask: {
      batch_id: 'some_batch_id'
    }
    inputSubtaskStartTime: 1471483858343
    outputProcessInfo: {
      "startTime": 1471483858343,
      "hasFiles": false
    }

  _queuePerFileSubtasks:
    inputTransaction1: "transaction"
    inputSubtask1: {}
    inputFiles1: [
      {
        "action": "Update",
        "listType": "Delete",
        "date": "20160406",
        "path": "Managed_Update/ASMT20160406/",
        "fileName": "Assessment_Update_Delete_20160406.txt",
        "fileType": "Delete",
        "startTime": 1471551965727,
        "dataType": "tax",
        "rawTableSuffix": "U_DELETES_20160406"
      },
      {
        "action": "Update",
        "listType": "Delete",
        "date": "20160406",
        "path": "Managed_Update/SAM20160406/",
        "fileName": "SAM_Update_Delete_20160406.txt",
        "fileType": "Delete",
        "startTime": 1471551965727,
        "dataType": "mortgage",
        "rawTableSuffix": "U_DELETES_20160406"
      }
    ]
    inputAction1: 'Delete'
    loadRawDataTaskArgs1: {
      "transaction": "transaction",
      "subtask": {},
      "laterSubtaskName": "loadRawData",
      "manualData": [],
      "replace": true,
      "concurrency": 10
    }
    recordChangeCountsTaskArgs1: {
      "transaction": "transaction",
      "subtask": {},
      "laterSubtaskName": "recordChangeCounts",
      "manualData": [],
      "replace": true,
      "concurrency": 80
    }




    inputTransaction2: "transaction"
    inputSubtask2: {}
    inputFiles2: [
      {
        "action": "Update",
        "listType": "Update",
        "date": "20160406",
        "path": "Managed_Update/ASMT20160406/",
        "fileName": "12021_Assessment_Update_20160406.txt.gz",
        "fileType": "Load",
        "startTime": 1471552572294,
        "dataType": "tax",
        "rawTableSuffix": "U_12021_20160406",
        "normalSubid": "12021",
        "indicateDeletes": false,
        "deletes": "indicated"
      },
      {
        "action": "Update",
        "listType": "Update",
        "date": "20160406",
        "path": "Managed_Update/Deed20160406/",
        "fileName": "12021_Deed_Update_20160406.txt.gz",
        "fileType": "Load",
        "startTime": 1471552572294,
        "dataType": "deed",
        "rawTableSuffix": "U_12021_20160406",
        "normalSubid": "12021",
        "indicateDeletes": false,
        "deletes": "indicated"
      },
      {
        "action": "Update",
        "listType": "Update",
        "date": "20160406",
        "path": "Managed_Update/SAM20160406/",
        "fileName": "12021_SAM_Update_20160406.txt.gz",
        "fileType": "Load",
        "startTime": 1471552572294,
        "dataType": "mortgage",
        "rawTableSuffix": "U_12021_20160406",
        "normalSubid": "12021",
        "indicateDeletes": false,
        "deletes": "indicated"
      }
    ]
    inputAction2: 'Update'
    loadRawDataTaskArgs2: {
      "transaction": "transaction",
      "subtask": {},
      "laterSubtaskName": "loadRawData",
      "manualData": [
        {
          "action": "Update",
          "listType": "Update",
          "date": "20160406",
          "path": "Managed_Update/ASMT20160406/",
          "fileName": "12021_Assessment_Update_20160406.txt.gz",
          "fileType": "Load",
          "startTime": 1471552572294,
          "dataType": "tax",
          "rawTableSuffix": "U_12021_20160406",
          "normalSubid": "12021",
          "indicateDeletes": false,
          "deletes": "indicated"
        },
        {
          "action": "Update",
          "listType": "Update",
          "date": "20160406",
          "path": "Managed_Update/Deed20160406/",
          "fileName": "12021_Deed_Update_20160406.txt.gz",
          "fileType": "Load",
          "startTime": 1471552572294,
          "dataType": "deed",
          "rawTableSuffix": "U_12021_20160406",
          "normalSubid": "12021",
          "indicateDeletes": false,
          "deletes": "indicated"
        },
        {
          "action": "Update",
          "listType": "Update",
          "date": "20160406",
          "path": "Managed_Update/SAM20160406/",
          "fileName": "12021_SAM_Update_20160406.txt.gz",
          "fileType": "Load",
          "startTime": 1471552572294,
          "dataType": "mortgage",
          "rawTableSuffix": "U_12021_20160406",
          "normalSubid": "12021",
          "indicateDeletes": false,
          "deletes": "indicated"
        }
      ],
      "replace": true,
      "concurrency": 10
    }
    recordChangeCountsTaskArgs2: {
      "transaction": "transaction",
      "subtask": {},
      "laterSubtaskName": "recordChangeCounts",
      "manualData": [
        {
          "action": "Update",
          "listType": "Update",
          "date": "20160406",
          "path": "Managed_Update/ASMT20160406/",
          "fileName": "12021_Assessment_Update_20160406.txt.gz",
          "fileType": "Load",
          "startTime": 1471552572294,
          "dataType": "tax",
          "rawTableSuffix": "U_12021_20160406",
          "normalSubid": "12021",
          "indicateDeletes": false,
          "deletes": "indicated"
        },
        {
          "action": "Update",
          "listType": "Update",
          "date": "20160406",
          "path": "Managed_Update/Deed20160406/",
          "fileName": "12021_Deed_Update_20160406.txt.gz",
          "fileType": "Load",
          "startTime": 1471552572294,
          "dataType": "deed",
          "rawTableSuffix": "U_12021_20160406",
          "normalSubid": "12021",
          "indicateDeletes": false,
          "deletes": "indicated"
        },
        {
          "action": "Update",
          "listType": "Update",
          "date": "20160406",
          "path": "Managed_Update/SAM20160406/",
          "fileName": "12021_SAM_Update_20160406.txt.gz",
          "fileType": "Load",
          "startTime": 1471552572294,
          "dataType": "mortgage",
          "rawTableSuffix": "U_12021_20160406",
          "normalSubid": "12021",
          "indicateDeletes": false,
          "deletes": "indicated"
        }
      ],
      "replace": true,
      "concurrency": 80
    }
}
