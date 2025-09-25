---
# 🧹 SQL Data Cleaning – Nashville Housing Dataset

This project demonstrates **data cleaning techniques in SQL Server** using the **Nashville Housing dataset**.
The goal is to transform messy raw data into a clean, standardized, and more usable format for analysis.

---

## 📂 Project Overview

The script walks through common **data cleaning tasks** including:

1. **Standardizing data formats**
2. **Populating missing values**
3. **Splitting columns into granular attributes**
4. **Normalizing categorical values**
5. **Removing duplicates**
6. **Dropping unused columns**

---

## ⚙️ Steps Performed

### 1️⃣ Standardize Data Format

* Converted the `SaleDate` column into a proper `DATE` format (`SalesDate`).

```sql
ALTER TABLE dbo.NashvilleHousing
ADD Salesdate DATE;

UPDATE NashvilleHousing
SET Salesdate = CONVERT(Date, SaleDate);
```

---

### 2️⃣ Populate Missing Property Addresses

* Filled missing `PropertyAddress` values by joining the table with itself on `ParcelID`.

```sql
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
  ON a.ParcelID = b.ParcelID
 AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;
```

---

### 3️⃣ Break Down Address into Components

* Split `PropertyAddress` into **Address** and **City**.
* Split `OwnerAddress` into **Address, City, State** using `PARSENAME()`.

Example:

```sql
ALTER TABLE dbo.NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255), PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1),
    PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));
```

---

### 4️⃣ Normalize Categorical Data

* Changed `SoldAsVacant` from `'Y'/'N'` → `'Yes'/'No'`.

```sql
UPDATE NashvilleHousing
SET SoldAsVacant = CASE
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;
```

---

### 5️⃣ Remove Duplicates

* Used `ROW_NUMBER()` with a CTE to identify and delete duplicate rows.

```sql
WITH CTE AS (
  SELECT *, ROW_NUMBER() OVER (
      PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
      ORDER BY UniqueID
  ) AS row_num
  FROM NashvilleHousing
)
DELETE FROM CTE WHERE row_num > 1;
```

---

### 6️⃣ Drop Unused Columns

* Removed unnecessary fields for cleaner data.

```sql
ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;
```

---

## ✅ Results

After applying the cleaning steps, the dataset is:

* **Standardized** (consistent formats)
* **Complete** (fewer missing values)
* **Structured** (split columns for better analysis)
* **Reliable** (duplicates removed, categories normalized)

---

## 📌 Usage

* Run the SQL script in **SQL Server Management Studio (SSMS)** or any SQL Server environment.
* Ensure you have the `SQL_DataCleaning` database created and the `NashvilleHousing` table loaded before running the script.

---

## 🏷️ Notes

* This project is intended as a **learning resource** for SQL data cleaning.
* You can adapt the same techniques to clean other datasets in SQL Server.

---

✍️ *Author: Osinusi Ayodeji

---

Do you want me to also add **a "Before vs After" table preview** in the README (showing messy vs cleaned data) so it looks more impressive on GitHub?

