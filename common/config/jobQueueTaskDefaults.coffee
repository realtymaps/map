module.exports =
  task:
    # name: '' # required
    description: 'Refresh mls data'
    data: '{}'
    ignore_until: null
    repeat_period_minutes: 15
    warn_timeout_minutes: 12
    kill_timeout_minutes: 14
    fail_retry_minutes: 1
    active: false

  subtask_loadRawData:
    # task_name: '' # required
    # name: '' # should be set to task-centric "#{task_name}_loadRawData"
    step_num: 1
    queue_name: 'mls'
    data: null
    retry_delay_seconds: 10
    retry_max_count: 10
    hard_fail_timeouts: false
    hard_fail_after_retries: true
    hard_fail_zombies: true
    warn_timeout_seconds: 600
    kill_timeout_seconds: 750
    auto_enqueue: true

  subtask_normalizeData:
    # task_name: '' # required
    # name: '' # should be set to task-centric "#{task_name}_normalizeData"
    step_num: 2
    queue_name: 'mls'
    data: null
    retry_delay_seconds: null
    retry_max_count: 0
    hard_fail_timeouts: true
    hard_fail_after_retries: true
    hard_fail_zombies: true
    warn_timeout_seconds: 60
    kill_timeout_seconds: 75
    auto_enqueue: false

  subtask_recordChangeCounts:
    # task_name: '' # required
    # name: '' # should be set to task-centric "#{task_name}_recordChangeCounts"
    step_num: 3
    queue_name: 'mls'
    data: null
    retry_delay_seconds: null
    retry_max_count: 0
    hard_fail_timeouts: true
    hard_fail_after_retries: true
    hard_fail_zombies: true
    warn_timeout_seconds: 30
    kill_timeout_seconds: 45
    auto_enqueue: false

  subtask_finalizeDataPrep:
    # task_name: '' # required
    # name: '' # should be set to task-centric "#{task_name}_finalizeDataPrep"
    step_num: 4
    queue_name: 'mls'
    data: null
    retry_delay_seconds: null
    retry_max_count: 0
    hard_fail_timeouts: true
    hard_fail_after_retries: true
    hard_fail_zombies: true
    warn_timeout_seconds: 30
    kill_timeout_seconds: 45
    auto_enqueue: false

  subtask_finalizeData:
    # task_name: '' # required
    # name: '' # should be set to task-centric "#{task_name}_finalizeData"
    step_num: 5
    queue_name: 'mls'
    data: null
    retry_delay_seconds: null
    retry_max_count: 0
    hard_fail_timeouts: true
    hard_fail_after_retries: true
    hard_fail_zombies: true
    warn_timeout_seconds: 600
    kill_timeout_seconds: 750
    auto_enqueue: false

  subtask_activateNewData:
    # task_name: '' # required
    # name: '' # should be set to task-centric "#{task_name}_activateNewData"
    step_num: 6
    queue_name: 'mls'
    data: null
    retry_delay_seconds: null
    retry_max_count: 0
    hard_fail_timeouts: true
    hard_fail_after_retries: true
    hard_fail_zombies: true
    warn_timeout_seconds: 240
    kill_timeout_seconds: 300
    auto_enqueue: false
