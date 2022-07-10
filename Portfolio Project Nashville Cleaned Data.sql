/*
Cleaning Data using SQL
*/

SELECT *
FROM CleaningProject.dbo.NashvilleHousing

-- Standardizing the Date format

--Checking the Standardized Date format. 
SELECT SaleDate, CONVERT(DATE, SaleDate)
FROM CleaningProject.dbo.NashvilleHousing

--Standarizing the Date format now by altering the table and adding a converted sale date column. 
ALTER TABLE CleaningProject.dbo.NashvilleHousing
ADD SaleDateConverted Date;

UPDATE CleaningProject.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(DATE, SaleDate)

--Populating Property Address data where the values are nulls where the ParcelID is similar(Using Parcel ID as reference point to populate this address)
--Checking the null data in PropertyAddress
SELECT *
FROM CleaningProject.dbo.NashvilleHousing
WHERE PropertyAddress is null

--If we look through the data we will notice that similar ParcelID has exact same PropertyAddress. 
SELECT *
FROM CleaningProject.dbo.NashvilleHousing
--WHERE PropertyAddress is null
ORDER BY ParcelID

--Using that ParcelID reference we will create a query where if the ParcelID 1 has an address and if ParcelID 2 does not have an address then lets populate it with ParcelID 1 address because the ParcelID 1=ParcelID 2
--We are Self Joining the table to look if ParcelID1 = ParcelID2
SELECT A1.ParcelID, A1.PropertyAddress, A2.ParcelID, A2.PropertyAddress, ISNULL(A1.PropertyAddress, A2.PropertyAddress)--What this is doing is checking if the values are ISNULL take the values from A2.PropertyAddress and put it in A1.PropertyAddress.
FROM CleaningProject.dbo.NashvilleHousing A1
JOIN CleaningProject.dbo.NashvilleHousing A2
ON A1.ParcelID = A2.ParcelID
AND A1.[UniqueID ]<> A2.[UniqueID ] --We did this because even if the ParcelID is the same but it has it's own UniqueID.
WHERE A1.PropertyAddress IS NULL

--Updating the table now. 
UPDATE A1
SET PropertyAddress = ISNULL(A1.PropertyAddress, A2.PropertyAddress)
FROM CleaningProject.dbo.NashvilleHousing A1
JOIN CleaningProject.dbo.NashvilleHousing A2
ON A1.ParcelID = A2.ParcelID
AND A1.[UniqueID ]<> A2.[UniqueID ]
WHERE A1.PropertyAddress IS NULL

--Breaking out Address(Property & Owner) in Seperate Columns (Address, City, State)
SELECT PropertyAddress
FROM CleaningProject.dbo.NashvilleHousing

--What this Substring is doing is looking at propertyaddress starting from 1st value and then it's going until the ,. 
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) AS Address
FROM CleaningProject.dbo.NashvilleHousing

--But we don't want this , after every address which we can change. Now using -1 after CHARINDEX what we are doing is we going to the , and then going -1 index back.  
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address
FROM CleaningProject.dbo.NashvilleHousing

--Now we are taking out the City column. So we are using +1 here because we want to capture the data after the ,. Then we are specifying where it needs to go finish. Because everysingle address has a different length we will use LEN(Address) to figure it out. 
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM CleaningProject.dbo.NashvilleHousing

--Updating the Splitted Address and City into new columns
--First for Address
ALTER TABLE CleaningProject.dbo.NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

UPDATE CleaningProject.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

--Now for City
ALTER TABLE CleaningProject.dbo.NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

UPDATE CleaningProject.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

--Checking if everything is added to our table in the end
--SELECT *
--FROM CleaningProject.dbo.NashvilleHousing

--Now we are gonna do the same thing for the Owner address
Select OwnerAddress
FROM CleaningProject.dbo.NashvilleHousing

--Using PARSENAME to split the address. PARSENAME does things backward
Select PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM CleaningProject.dbo.NashvilleHousing

--Updating the Splitted Address, City and State into new columns
--First for Address
ALTER TABLE CleaningProject.dbo.NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE CleaningProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

--Next for City
ALTER TABLE CleaningProject.dbo.NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

UPDATE CleaningProject.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

--Lastly for State
ALTER TABLE CleaningProject.dbo.NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

UPDATE CleaningProject.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

--Checking our tables now
--SELECT *
--FROM CleaningProject.dbo.NashvilleHousing

--Now we are changing the Y and N values to 'Yes' and 'No' values in the SoldAsVacant column
--Checking for Y and N values
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM CleaningProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY COUNT(SoldAsVacant)

--Using Case Statement to change Y and N values to 'Yes' and 'No' values
SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END
FROM CleaningProject.dbo.NashvilleHousing

--Updating the table
UPDATE CleaningProject.dbo.NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END

--Removing Duplicates from the data. Usually we don't delete data from our table therefore we are gonna use a CTE/temp table to present it. 
--We are gonna PARTITION the duplicate rows where the data can be the same for eg if parcelid, address, saledate, legalreference all four are the same for two rows then they are the same data and we don't need duplicates.
WITH DupNumCTE AS
(
SELECT *,
ROW_NUMBER() OVER 
(
PARTITION BY ParcelID, PropertyAddress, SalePrice, LegalReference
ORDER BY UniqueID 
) AS ROW_NUM
FROM CleaningProject.dbo.NashvilleHousing
)
SELECT * --Instead of SELECT * we used DELETE to remove all the duplicates, then checked if all the duplicates are gone. 
FROM DupNumCTE
WHERE ROW_NUM > 1

--Deleting Unused Columns. We don't usually do this on RAW data. 
--So deleting the columns we don't need now like SaleDate, PropertyAddress & OwnerAddres because we already splitted them and created columns for them. 
ALTER TABLE CleaningProject.dbo.NashvilleHousing
DROP COLUMN SaleDate, OwnerAddress, PropertyAddress

SELECT *
FROM CleaningProject.dbo.NashvilleHousing