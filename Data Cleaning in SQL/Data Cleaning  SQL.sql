-- CREATE DATABASE SQL_DataCleaning;
/*
-- Cleaning Data in SQL Queries

*/
SELECT	*
FROM	SQL_DataCleaning.dbo.NashvilleHousing;

------------------------------------------------------------------------------------------------------------

-- Standardize Data Format

USE SQL_DataCleaning;

SELECT	*
FROM	SQL_DataCleaning.dbo.NashvilleHousing;

ALTER TABLE dbo.NashvilleHousing
ADD Salesdate DATE;

UPDATE NashvilleHousing
SET Salesdate = CONVERT(Date, SaleDate)

----------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

SELECT	a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, B.PropertyAddress)
FROM	SQL_DataCleaning.dbo.NashvilleHousing a
JOIN	SQL_DataCleaning.dbo.NashvilleHousing b
		ON a.ParcelID = b.ParcelID
		AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM	SQL_DataCleaning.dbo.NashvilleHousing a
JOIN	SQL_DataCleaning.dbo.NashvilleHousing b
		ON a.ParcelID = b.ParcelID
		AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

-- Breaking out Address Into Individual	Columns (Address, City, State) which include these colomns(PropertyAddress, OwnerAddress)

SELECT	PropertyAddress
FROM	SQL_DataCleaning.dbo.NashvilleHousing; 

SELECT 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
	SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS Address
FROM	SQL_DataCleaning.dbo.NashvilleHousing;

ALTER TABLE dbo.NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE dbo.NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

SELECT	OwnerAddress
FROM	SQL_DataCleaning.dbo.NashvilleHousing;

SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM	SQL_DataCleaning.dbo.NashvilleHousing;

ALTER TABLE dbo.NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

ALTER TABLE dbo.NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity  = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

ALTER TABLE dbo.NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

----------------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT	DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM	SQL_DataCleaning.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2 DESC;

SELECT	SoldAsVacant,
		(CASE
			WHEN SoldAsVacant = 'Y' THEN 'Yes'
			WHEN SoldAsVacant = 'N' THEN 'No'
			ELSE SoldAsVacant 
		END) 
FROM	SQL_DataCleaning.dbo.NashvilleHousing;

UPDATE NashvilleHousing
SET SoldAsVacant = (CASE
						WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant 
					END) 

--------------------------------------------------------------------------------------------------------------------------------
-- Next Step, Removing Duplicates 
WITH CTE AS (SELECT *, 
				ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
								  ORDER BY UniqueID) AS row_num
			 FROM	SQL_DataCleaning.dbo.NashvilleHousing)
DELETE 
FROM CTE
WHERE row_num > 1
--------------------------------------------------------------------------------------------------------------------------------
-- Delete Unused Column
ALTER TABLE	SQL_DataCleaning.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

The End...


