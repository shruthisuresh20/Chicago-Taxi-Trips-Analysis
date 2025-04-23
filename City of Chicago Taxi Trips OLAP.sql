CREATE DATABASE taxi_dw;
USE taxi_dw;

SHOW TABLES;

-- Validate if the data is successfully inserted
SELECT COUNT(*) FROM taxi_trips;

-- Creating the Fact Table
CREATE TABLE taxi_trips_fact (
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

-- Time Dimension
CREATE TABLE time_dim (
    Time_ID INT AUTO_INCREMENT PRIMARY KEY,
    Trip_Date DATE,
    Trip_Hour INT,
    Day_Of_Week VARCHAR(10),
    Month INT,
    Year INT
);

-- Location Dimension
CREATE TABLE location_dim (
    Location_ID INT AUTO_INCREMENT PRIMARY KEY,
    Community_Area DOUBLE,
    Census_Tract DOUBLE,
    Centroid_Latitude DOUBLE,
    Centroid_Longitude DOUBLE,
    Location_Description VARCHAR(100)
);

-- Describe the Fact and Dimension tables
DESC taxi_trips;
DESC taxi_trips_fact;
DESC time_dim;
DESC location_dim;

-- SQL Query to Populate taxi_trips_fact
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
    AND tt.`Dropoff Census Tract` = dl.Census_Tract;

-- ETL Validation: Validate if the data is successfully inserted
SELECT COUNT(*) FROM taxi_trips_fact;
SELECT COUNT(*) FROM time_dim;
SELECT COUNT(*) FROM location_dim;

-- OLAP Queries

-- 1. Roll-Up: Monthly Revenue Analysis for Top 5 Locations & Companies
-- (Aggregates revenue at the monthly level for the top 5 locations and top 5 taxi companies)

WITH top_locations AS (
    SELECT Pickup_Location_ID, 
           SUM(Trip_Total) AS total_revenue
    FROM taxi_trips_fact
    GROUP BY Pickup_Location_ID
    ORDER BY total_revenue DESC
    LIMIT 5
),
top_companies AS (
    SELECT Company, 
           SUM(Trip_Total) AS total_revenue
    FROM taxi_trips_fact
    GROUP BY Company
    ORDER BY total_revenue DESC
    LIMIT 5
)
SELECT 
    t.Year, 
    t.Month, 
    l.Community_Area AS Location, 
    f.Company, 
    SUM(f.Trip_Total) AS Monthly_Revenue
FROM taxi_trips_fact f
JOIN time_dim t ON f.Time_ID = t.Time_ID
JOIN location_dim l ON f.Pickup_Location_ID = l.Location_ID
WHERE f.Pickup_Location_ID IN (SELECT Pickup_Location_ID FROM top_locations)
AND f.Company IN (SELECT Company FROM top_companies)
GROUP BY t.Year, t.Month, l.Community_Area, f.Company
ORDER BY t.Year, t.Month, Monthly_Revenue DESC;

-- 2. Drill-Down: Breaking Down Revenue by Taxi Company to Individual Drivers
-- (From company-level revenue to individual driver earnings within each company)

SELECT 
    f.Company,
    f.Taxi_ID,
    SUM(f.Trip_Total) AS Driver_Revenue
FROM taxi_trips_fact f
GROUP BY f.Company, f.Taxi_ID
ORDER BY f.Company, Driver_Revenue DESC;

-- 3. Slice: Night Drop-Off Analysis
-- (Filters for trips with drop-offs between 8 PM - 4 AM)

SELECT 
    l.Community_Area AS Dropoff_Location, 
    COUNT(*) AS Total_Trips,
    SUM(f.Trip_Total) AS Total_Revenue
FROM taxi_trips_fact f
JOIN time_dim t ON f.Time_ID = t.Time_ID
JOIN location_dim l ON f.Dropoff_Location_ID = l.Location_ID
WHERE t.Trip_Hour BETWEEN 20 AND 23  -- 8 PM to 11 PM
   OR t.Trip_Hour BETWEEN 0 AND 4   -- 12 AM to 4 AM
GROUP BY l.Community_Area
ORDER BY Total_Revenue DESC;


-- 4. Dice: Average Fare by Hour and Community Areas Over a Date Range
-- (Filters by multiple dimensions: Time Range & Pickup Community Area, then groups by hour)

SELECT 
    t.Trip_Hour, 
    l.Community_Area AS Pickup_Area,
    AVG(f.Fare) AS Avg_Fare
FROM taxi_trips_fact f
JOIN time_dim t ON f.Time_ID = t.Time_ID
JOIN location_dim l ON f.Pickup_Location_ID = l.Location_ID
WHERE t.Trip_Date BETWEEN '2024-04-01' AND '2024-04-30'  -- Date Range
AND l.Community_Area IN (8, 28, 32)  -- Specific Community Areas
GROUP BY t.Trip_Hour, l.Community_Area
ORDER BY t.Trip_Hour, l.Community_Area;

-- 5. Pivot: Grouping by Time of Day

SELECT 
    t.Trip_Hour,
    SUM(f.Tips) AS Total_Tips,
    SUM(f.Fare) AS Total_Fare,
    ROUND((SUM(f.Tips) / SUM(f.Fare)) * 100, 2) AS Tip_Percentage
FROM taxi_trips_fact f
JOIN time_dim t ON f.Time_ID = t.Time_ID
GROUP BY t.Trip_Hour
ORDER BY t.Trip_Hour;