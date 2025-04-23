USE taxi_dw;

-- Creating the Fact Table
CREATE TABLE IF NOT EXISTS taxi_trips_fact (
    Fact_ID INT AUTO_INCREMENT PRIMARY KEY,
    Trip_ID VARCHAR(50),  
    Taxi_ID VARCHAR(255),
    Time_ID INT,  -- FK from time_dim
    Pickup_Location_ID INT,  -- FK from location_dim
    Dropoff_Location_ID INT,  -- FK from location_dim
    Trip_Seconds DOUBLE,
    Trip_Miles DOUBLE,
    Fare DOUBLE,
    Tips DOUBLE,
    Tolls DOUBLE,
    Extras DOUBLE,
    Trip_Total DOUBLE,
    Payment_Type VARCHAR(50),
    Company VARCHAR(100),
    Trip_Status VARCHAR(50),
    FOREIGN KEY (Time_ID) REFERENCES time_dim(Time_ID),
    FOREIGN KEY (Pickup_Location_ID) REFERENCES location_dim(Location_ID),
    FOREIGN KEY (Dropoff_Location_ID) REFERENCES location_dim(Location_ID)
);

-- Creating Dimension Tables
CREATE TABLE IF NOT EXISTS time_dim (
    Time_ID INT AUTO_INCREMENT PRIMARY KEY,
    Trip_Date DATE,
    Trip_Hour INT,
    Day_Of_Week VARCHAR(10),
    Month INT,
    Year INT
);

CREATE TABLE IF NOT EXISTS location_dim (
    Location_ID INT AUTO_INCREMENT PRIMARY KEY,
    Community_Area DOUBLE,
    Census_Tract DOUBLE,
    Centroid_Latitude DOUBLE,
    Centroid_Longitude DOUBLE,
    Location_Description VARCHAR(100)
);

-- Incremental Update Queries
-- Fetch latest trip date from taxi_trips_fact
SELECT MAX(t.Trip_Date) 
FROM taxi_trips_fact f
JOIN time_dim t ON f.Time_ID = t.Time_ID;

-- Insert new dates into time_dim if they don’t exist
INSERT INTO time_dim (Trip_Date, Trip_Hour, Day_Of_Week, Month, Year)
SELECT DISTINCT DATE(Trip_Start_Timestamp), HOUR(Trip_Start_Timestamp), 
       DAYNAME(Trip_Start_Timestamp), MONTH(Trip_Start_Timestamp), YEAR(Trip_Start_Timestamp)
FROM taxi_trips
WHERE Trip_Start_Timestamp > (SELECT MAX(t.Trip_Date) FROM taxi_trips_fact f
                              JOIN time_dim t ON f.Time_ID = t.Time_ID);

-- Insert new locations into location_dim if they don’t exist
INSERT INTO location_dim (Community_Area, Census_Tract, Centroid_Latitude, Centroid_Longitude)
SELECT DISTINCT Pickup_Community_Area, Pickup_Census_Tract, Pickup_Centroid_Latitude, Pickup_Centroid_Longitude
FROM taxi_trips
WHERE Pickup_Community_Area NOT IN (SELECT Community_Area FROM location_dim);

-- Insert only new trips into taxi_trips_fact
INSERT INTO taxi_trips_fact (
    Trip_ID, Taxi_ID, Time_ID, Pickup_Location_ID, Dropoff_Location_ID,
    Trip_Seconds, Trip_Miles, Fare, Tips, Tolls, Extras, Trip_Total,
    Payment_Type, Company, Trip_Status
)
SELECT 
    tt.`Trip ID`, 
    tt.`Taxi ID`, 
    t.Time_ID,
    pl.Location_ID AS Pickup_Location_ID,
    dl.Location_ID AS Dropoff_Location_ID,
    tt.`Trip Seconds`, tt.`Trip Miles`, 
    tt.Fare, tt.Tips, tt.Tolls, tt.Extras, tt.`Trip Total`, 
    tt.`Payment Type`, tt.Company, tt.`Trip Status`
FROM taxi_trips tt
JOIN time_dim t 
    ON DATE(tt.`Trip Start Timestamp`) = t.Trip_Date
    AND tt.`Trip Start Hour` = t.Trip_Hour
JOIN location_dim pl 
    ON tt.`Pickup Community Area` = pl.Community_Area
    AND tt.`Pickup Census Tract` = pl.Census_Tract
JOIN location_dim dl 
    ON tt.`Dropoff Community Area` = dl.Community_Area
    AND tt.`Dropoff Census Tract` = dl.Census_Tract
WHERE tt.`Trip Start Timestamp` > (SELECT MAX(t.Trip_Date) FROM taxi_trips_fact f
                                   JOIN time_dim t ON f.Time_ID = t.Time_ID);

-- Example Queries for January - March 2024

-- Monthly Revenue Analysis for Q1 2024
SELECT 
    t.Year, t.Month, 
    l.Community_Area AS Location, 
    f.Company, 
    SUM(f.Trip_Total) AS Monthly_Revenue
FROM taxi_trips_fact f
JOIN time_dim t ON f.Time_ID = t.Time_ID
JOIN location_dim l ON f.Pickup_Location_ID = l.Location_ID
WHERE t.Year = 2024 AND t.Month BETWEEN 1 AND 3
GROUP BY t.Year, t.Month, l.Community_Area, f.Company
ORDER BY t.Year, t.Month, Monthly_Revenue DESC;

-- Peak Hour Analysis for Q1 2024
SELECT 
    t.Trip_Hour, 
    COUNT(*) AS Total_Trips, 
    AVG(f.Fare) AS Avg_Fare
FROM taxi_trips_fact f
JOIN time_dim t ON f.Time_ID = t.Time_ID
WHERE t.Year = 2024 AND t.Month BETWEEN 1 AND 3
GROUP BY t.Trip_Hour
ORDER BY Total_Trips DESC;

-- CRON Job to Automate Incremental Updates (Runs on 1st of Every Month at 2 AM)
-- Add this to the crontab using `crontab -e`
-- 0 2 1 * * /usr/bin/mysql -u your_user -p'your_password' taxi_dw < /path/to/incremental_updates.sql