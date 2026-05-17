{% macro date_diff_days(start_date, end_date) %}
    DATEDIFF('day', {{ start_date }}, {{ end_date }})
{% endmacro %}