-- SQL script to update permits table for hourly permits
ALTER TABLE permits 
ADD COLUMN is_hourly TINYINT(1) DEFAULT 0 AFTER attachment,
ADD COLUMN start_time TIME NULL AFTER is_hourly,
ADD COLUMN end_time TIME NULL AFTER start_time;
