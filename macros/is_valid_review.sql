{% macro is_valid_review(score_column) %}
    CASE
        WHEN {{ score_column }} BETWEEN 1 AND 5 THEN TRUE
        ELSE FALSE
    END
{% endmacro %}