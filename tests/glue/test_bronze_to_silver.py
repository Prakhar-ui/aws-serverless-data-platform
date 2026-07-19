"""Tests for bronze_to_silver_statistics.py transforms."""
from pyspark.sql import functions as F
import pytest


def test_enforce_schema_kaggle_format(spark, bronze_to_silver_module):
    """Test enforce_schema with Kaggle CSV format columns (the else branch)."""
    module = bronze_to_silver_module
    
    schema = 'video_id string, trending_date string, title string, channel_title string, category_id long, publish_time string, tags string, views long, likes long, dislikes long, comment_count long, thumbnail_link string, comments_disabled boolean, ratings_disabled boolean, video_error_or_removed boolean, description string, region string'
    data = [('vid_1', '24.07.17', 'Title', 'Channel', 10, '2024-07-17T00:00:00Z', '', 100, 10, 1, 5, 'http://example.com/thumb.jpg', False, False, False, 'desc', 'US')]
    df = spark.createDataFrame(data, schema)
    
    result_df = module.enforce_schema(df)
    
    assert 'video_id' in result_df.columns
    assert 'region' in result_df.columns
    assert result_df.count() == 1
    assert result_df.select('category_id').collect()[0][0] == 10
    assert result_df.select('views').collect()[0][0] == 100


def test_cleanse_data_removes_null_video_id(spark, bronze_to_silver_module):
    module = bronze_to_silver_module
    
    schema = 'video_id string, region string, trending_date string, views long, likes long, dislikes long, comment_count long'
    data = [
        (None, 'US', '24.07.17', 100, 10, 1, 5),
        ('vid_1', 'US', '24.07.17', 200, 20, 2, 10),
    ]
    df = spark.createDataFrame(data, schema)
    
    result_df = module.cleanse_data(df, 'test_job')
    
    assert result_df.count() == 1
    assert result_df.filter(F.col('video_id') == 'vid_1').count() == 1


def test_cleanse_data_adds_derived_metrics(spark, bronze_to_silver_module):
    module = bronze_to_silver_module
    
    schema = 'video_id string, region string, trending_date string, views long, likes long, dislikes long, comment_count long'
    data = [('vid_1', 'US', '24.07.17', 200, 20, 2, 10)]
    df = spark.createDataFrame(data, schema)
    
    result_df = module.cleanse_data(df, 'test_job')
    
    assert result_df.count() == 1
    assert 'like_ratio' in result_df.columns
    assert 'engagement_rate' in result_df.columns
    assert '_processed_at' in result_df.columns
    assert '_job_name' in result_df.columns


def test_cleanse_data_normalizes_region_to_lower(spark, bronze_to_silver_module):
    module = bronze_to_silver_module
    
    schema = 'video_id string, region string, trending_date string, views long, likes long, dislikes long, comment_count long'
    df = spark.createDataFrame([('vid_1', 'US', '24.07.17', 100, 10, 1, 5)], schema)
    
    result_df = module.cleanse_data(df, 'test_job')
    
    assert result_df.select(F.col('region')).collect()[0][0] == 'us'


def test_deduplicate_data_keeps_latest(spark, bronze_to_silver_module):
    module = bronze_to_silver_module
    
    schema = 'video_id string, region string, trending_date_parsed date, _processed_at timestamp'
    from datetime import datetime, date
    
    data = [
        ('vid_1', 'us', date(2024, 7, 17), datetime(2024, 7, 17, 10, 0, 0)),
        ('vid_1', 'us', date(2024, 7, 17), datetime(2024, 7, 17, 11, 0, 0)),  # later = keep
    ]
    df = spark.createDataFrame(data, schema)
    
    result_df = module.deduplicate_data(df)
    
    assert result_df.count() == 1
    assert result_df.select(F.col('_processed_at')).collect()[0][0] == datetime(2024, 7, 17, 11, 0, 0)


def test_run_data_quality_checks_identifies_nulls(spark, bronze_to_silver_module):
    module = bronze_to_silver_module
    
    schema = 'video_id string, title string, channel_title string, views long'
    data = [
        (None, 'Title1', 'Channel1', 100),
        ('vid_2', None, 'Channel2', 200),
        ('vid_3', 'Title3', None, -5),
    ]
    df = spark.createDataFrame(data, schema)
    
    # Mock logger
    class MockLogger:
        def warn(self, msg):
            pass
    
    results = module.run_data_quality_checks(df, MockLogger())
    
    assert results['nulls']['video_id'] == 1
    assert results['nulls']['title'] == 1
    assert results['nulls']['channel_title'] == 1
    assert results['negative_views'] == 1
