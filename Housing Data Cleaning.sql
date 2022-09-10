--  Cleaning Housing Data
USE PortfolioProject
SELECT *
FROM Housing

-- Explore column data types
SELECT DATA_TYPE
from INFORMATION_SCHEMA.COLUMNS
where
table_schema = PortfolioProject and table_name = Housing

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Housing'


-- Populate property address data

-- Step 1: Find out if NULL values exist
SELECT *
FROM Housing
WHERE PropertyAddress IS NULL

-- Step 2: Check if for the same parcelid the address is filled once and NULL the other time. Indeed this is the case, and
-- this is probably a case of row dependency
SELECT a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Housing a
    JOIN Housing b ON (a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID)
WHERE a.propertyaddress IS NULL

-- Step 3: Use ISNULL function to say "if this thing is NULL, fill it with an existing address in the same other parcelid"
UPDATE a
SET propertyaddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Housing a
    JOIN Housing b ON (a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID)
WHERE a.propertyaddress IS NULL

-- Break out the address into individual columns

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) AS Address,
    SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+2, len(propertyaddress)) AS City
FROM Housing

-- Above is the method we separate address and city through the comma, now we put those two columns in the table
ALTER TABLE Housing
ADD PropertySplitAddress varchar(100)

ALTER TABLE Housing
ADD PropertySplitCity varchar(100)

Update Housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)

Update Housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+2, len(PropertyAddress))

-- Check update result
SELECT *
FROM Housing

-- Now split the OwnerAddress into three columns (also Normalization)
SELECT OwnerAddress
FROM Housing

-- This time we use a different method, PARSENAME
SELECT
    PARSENAME(REPLACE(OwnerAddress,',','.' ),3) AS Address,
    PARSENAME(REPLACE(OwnerAddress,',','.' ),2),
    PARSENAME(REPLACE(OwnerAddress,',','.' ),1)
FROM Housing

-- Update the tables
ALTER TABLE Housing
ADD OwnerSplitAddress varchar(100)

ALTER TABLE Housing
ADD OwnerSplitCity varchar(100)

ALTER TABLE Housing
ADD OwnerSplitState varchar(100)

UPDATE Housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.' ),3)

UPDATE Housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

UPDATE Housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

-- Check update result
SELECT *
FROM Housing

-- Change Y and N to Yes and No in "SoldAsVacant" field

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM Housing
GROUP BY SoldAsVacant

-- Use Case Statement here
-- This is just showing how the transformation works. Doesn't update anything yet.
SELECT SoldAsVacant,
(CASE When SoldAsVacant = 'Y'
    THEN 'Yes'
    WHEN SoldAsVacant = 'N'
    THEN 'No'
    ELSE SoldAsVacant
    END)
FROM Housing

-- To make changes to our original column, we need to UPDATE.
UPDATE Housing
SET SoldAsVacant =
(CASE When SoldAsVacant = 'Y'
    THEN 'Yes'
    WHEN SoldAsVacant = 'N'
    THEN 'No'
    ELSE SoldAsVacant
    END)

SELECT DISTINCT SoldAsVacant FROM Housing

-- Remove Duplicates
-- (Usually we don't delete data from the database, we just filter it when loading it into a temp table)
WITH CTE_Dups (UniqueID, ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference,RowNum) AS
(
SELECT UniqueID, ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference,
ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) Row_Num
FROM Housing)
SELECT * FROM CTE_Dups
WHERE RowNum > 1

-- Delete Unused Columns (Just dropping columns we know we won't use)
ALTER TABLE Housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

SELECT * FROM Housing