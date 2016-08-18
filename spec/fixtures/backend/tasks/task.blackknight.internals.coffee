module.exports = {
  filterS3Contents:
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
      "Refresh": [],
      "Update": [
        {
          "action": "Update",
          "listType": "Update",
          "date": "20160406",
          "path": "Managed_Update/ASMT20160406/12021_Assessment_Update_20160406.txt.gz",
          "fileName": "12021_Assessment_Update_20160406.txt.gz",
          "fileType": "Load",
          "startTime": 1471482558075,
          "dataType": "tax",
          "rawTableSuffix": "12021_Assessment_Update_20160406",
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
          "path": "Managed_Update/ASMT20160406/Assessment_Update_Delete_20160406.txt",
          "fileName": "Assessment_Update_Delete_20160406.txt",
          "fileType": "Delete",
          "startTime": 1471482558075,
          "dataType": "tax",
          "rawTableSuffix": "Assessment_Update_Delete_20160406"
        }
      ]
    }



  getProcessInfo:
    inputSubtask: {}
    inputSubtaskStartTime: 1471483858343
    outputProcessInfo: {
      "dates": {
        "Refresh": "20160406",
        "Update": "20160406"
      },
      "hasFiles": true,
      "startTime": 1471483858343,
      "Refresh": [],
      "Update": [
        {
          "action": "Update",
          "listType": "Update",
          "date": "20160406",
          "path": "Managed_Update/ASMT20160406/12021_Assessment_Update_20160406.txt.gz",
          "fileName": "12021_Assessment_Update_20160406.txt.gz",
          "fileType": "Load",
          "startTime": 1471483858343,
          "dataType": "tax",
          "rawTableSuffix": "12021_Assessment_Update_20160406",
          "normalSubid": "12021",
          "indicateDeletes": false,
          "deletes": "indicated"
        },
        {
          "action": "Update",
          "listType": "Update",
          "date": "20160406",
          "path": "Managed_Update/Deed20160406/12021_Deed_Update_20160406.txt.gz",
          "fileName": "12021_Deed_Update_20160406.txt.gz",
          "fileType": "Load",
          "startTime": 1471483858343,
          "dataType": "deed",
          "rawTableSuffix": "12021_Deed_Update_20160406",
          "normalSubid": "12021",
          "indicateDeletes": false,
          "deletes": "indicated"
        },
        {
          "action": "Update",
          "listType": "Update",
          "date": "20160406",
          "path": "Managed_Update/SAM20160406/12021_SAM_Update_20160406.txt.gz",
          "fileName": "12021_SAM_Update_20160406.txt.gz",
          "fileType": "Load",
          "startTime": 1471483858343,
          "dataType": "mortgage",
          "rawTableSuffix": "12021_SAM_Update_20160406",
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
          "path": "Managed_Update/ASMT20160406/Assessment_Update_Delete_20160406.txt",
          "fileName": "Assessment_Update_Delete_20160406.txt",
          "fileType": "Delete",
          "startTime": 1471483858343,
          "dataType": "tax",
          "rawTableSuffix": "Assessment_Update_Delete_20160406"
        },
        {
          "action": "Update",
          "listType": "Delete",
          "date": "20160406",
          "path": "Managed_Update/SAM20160406/SAM_Update_Delete_20160406.txt",
          "fileName": "SAM_Update_Delete_20160406.txt",
          "fileType": "Delete",
          "startTime": 1471483858343,
          "dataType": "mortgage",
          "rawTableSuffix": "SAM_Update_Delete_20160406"
        }
      ]
    }
  queuePerFileSubtasks:
    inputTransaction1: "transaction"
    inputSubtask1: {}
    inputFiles1: [
      {
        "action": "Update",
        "listType": "Delete",
        "date": "20160406",
        "path": "Managed_Update/ASMT20160406/Assessment_Update_Delete_20160406.txt",
        "fileName": "Assessment_Update_Delete_20160406.txt",
        "fileType": "Delete",
        "startTime": 1471551965727,
        "dataType": "tax",
        "rawTableSuffix": "Assessment_Update_Delete_20160406"
      },
      {
        "action": "Update",
        "listType": "Delete",
        "date": "20160406",
        "path": "Managed_Update/SAM20160406/SAM_Update_Delete_20160406.txt",
        "fileName": "SAM_Update_Delete_20160406.txt",
        "fileType": "Delete",
        "startTime": 1471551965727,
        "dataType": "mortgage",
        "rawTableSuffix": "SAM_Update_Delete_20160406"
      }
    ]
    inputAction1: 'Delete'
    loadRawDataTaskArgs1: {
      "transaction": "transaction",
      "subtask": {},
      "laterSubtaskName": "loadRawData",
      "manualData": [
        {
          "action": "Update",
          "listType": "Delete",
          "date": "20160406",
          "path": "Managed_Update/ASMT20160406/Assessment_Update_Delete_20160406.txt",
          "fileName": "Assessment_Update_Delete_20160406.txt",
          "fileType": "Delete",
          "startTime": 1471551965727,
          "dataType": "tax",
          "rawTableSuffix": "Assessment_Update_Delete_20160406"
        },
        {
          "action": "Update",
          "listType": "Delete",
          "date": "20160406",
          "path": "Managed_Update/SAM20160406/SAM_Update_Delete_20160406.txt",
          "fileName": "SAM_Update_Delete_20160406.txt",
          "fileType": "Delete",
          "startTime": 1471551965727,
          "dataType": "mortgage",
          "rawTableSuffix": "SAM_Update_Delete_20160406"
        }
      ],
      "replace": true,
      "concurrency": 10
    }
    recordChangeCountsTaskArgs1: {
      "transaction": "transaction",
      "subtask": {},
      "laterSubtaskName": "recordChangeCounts",
      "manualData": [
        {
          "action": "Update",
          "listType": "Delete",
          "date": "20160406",
          "path": "Managed_Update/ASMT20160406/Assessment_Update_Delete_20160406.txt",
          "fileName": "Assessment_Update_Delete_20160406.txt",
          "fileType": "Delete",
          "startTime": 1471551965727,
          "dataType": "tax",
          "rawTableSuffix": "Assessment_Update_Delete_20160406"
        },
        {
          "action": "Update",
          "listType": "Delete",
          "date": "20160406",
          "path": "Managed_Update/SAM20160406/SAM_Update_Delete_20160406.txt",
          "fileName": "SAM_Update_Delete_20160406.txt",
          "fileType": "Delete",
          "startTime": 1471551965727,
          "dataType": "mortgage",
          "rawTableSuffix": "SAM_Update_Delete_20160406"
        }
      ],
      "replace": true
    }




    inputTransaction2: "transaction"
    inputSubtask2: {}
    inputFiles2: [
      {
        "action": "Update",
        "listType": "Update",
        "date": "20160406",
        "path": "Managed_Update/ASMT20160406/12021_Assessment_Update_20160406.txt.gz",
        "fileName": "12021_Assessment_Update_20160406.txt.gz",
        "fileType": "Load",
        "startTime": 1471552572294,
        "dataType": "tax",
        "rawTableSuffix": "12021_Assessment_Update_20160406",
        "normalSubid": "12021",
        "indicateDeletes": false,
        "deletes": "indicated"
      },
      {
        "action": "Update",
        "listType": "Update",
        "date": "20160406",
        "path": "Managed_Update/Deed20160406/12021_Deed_Update_20160406.txt.gz",
        "fileName": "12021_Deed_Update_20160406.txt.gz",
        "fileType": "Load",
        "startTime": 1471552572294,
        "dataType": "deed",
        "rawTableSuffix": "12021_Deed_Update_20160406",
        "normalSubid": "12021",
        "indicateDeletes": false,
        "deletes": "indicated"
      },
      {
        "action": "Update",
        "listType": "Update",
        "date": "20160406",
        "path": "Managed_Update/SAM20160406/12021_SAM_Update_20160406.txt.gz",
        "fileName": "12021_SAM_Update_20160406.txt.gz",
        "fileType": "Load",
        "startTime": 1471552572294,
        "dataType": "mortgage",
        "rawTableSuffix": "12021_SAM_Update_20160406",
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
          "path": "Managed_Update/ASMT20160406/12021_Assessment_Update_20160406.txt.gz",
          "fileName": "12021_Assessment_Update_20160406.txt.gz",
          "fileType": "Load",
          "startTime": 1471552572294,
          "dataType": "tax",
          "rawTableSuffix": "12021_Assessment_Update_20160406",
          "normalSubid": "12021",
          "indicateDeletes": false,
          "deletes": "indicated"
        },
        {
          "action": "Update",
          "listType": "Update",
          "date": "20160406",
          "path": "Managed_Update/Deed20160406/12021_Deed_Update_20160406.txt.gz",
          "fileName": "12021_Deed_Update_20160406.txt.gz",
          "fileType": "Load",
          "startTime": 1471552572294,
          "dataType": "deed",
          "rawTableSuffix": "12021_Deed_Update_20160406",
          "normalSubid": "12021",
          "indicateDeletes": false,
          "deletes": "indicated"
        },
        {
          "action": "Update",
          "listType": "Update",
          "date": "20160406",
          "path": "Managed_Update/SAM20160406/12021_SAM_Update_20160406.txt.gz",
          "fileName": "12021_SAM_Update_20160406.txt.gz",
          "fileType": "Load",
          "startTime": 1471552572294,
          "dataType": "mortgage",
          "rawTableSuffix": "12021_SAM_Update_20160406",
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
      "manualData": [],
      "replace": true
    }
}
