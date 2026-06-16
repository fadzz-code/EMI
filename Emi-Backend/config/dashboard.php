<?php

return [
    'default_period_days' => (int) env('DASHBOARD_DEFAULT_PERIOD_DAYS', 30),
    'max_period_days' => (int) env('DASHBOARD_MAX_PERIOD_DAYS', 366),
    'default_per_page' => (int) env('DASHBOARD_DEFAULT_PER_PAGE', 20),
    'max_per_page' => (int) env('DASHBOARD_MAX_PER_PAGE', 100),
    'export_max_rows' => (int) env('REPORT_EXPORT_MAX_ROWS', 50000),
];
