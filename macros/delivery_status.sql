{% macro delivery_status(actual_days, estimated_days) %}
    CASE
        WHEN {{ actual_days }} IS NULL THEN 'not_delivered'
        WHEN {{ actual_days }} <= {{ estimated_days }} THEN 'on_time'
        WHEN {{ actual_days }} > {{ estimated_days }} THEN 'late'
        ELSE 'unknown'
    END
{% endmacro %}