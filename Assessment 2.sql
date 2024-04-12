CREATE SCHEMA adventure_works;

USE adventure_works;


#Q1: To populate a new record in Orders, we need to ensure we use existing (or populate):
# 1. employees
# 2. productsubcategories
# 3. customers
# 4. products
# 5. productcategories

#For this question, let us save time and add a record into Products.
INSERT INTO products (ProductID, ProductNumber, ProductName, ModelName, MakeFlag, StandardCost,
					  ListPrice, SubcategoryID)
			SELECT a.ProductID + 1, 'DK-LMAO-69', 'DK Road Frame - White, 69', 'DK Road Frame',
				   1, 6666.31, 15321.5, 14
            FROM products as a 
			ORDER BY a.ProductID DESC LIMIT 1;
	
SELECT * FROM products
ORDER BY ProductID DESC;


#Question 2a:
INSERT INTO customers (CustomerID, FirstName, LastName)
		SELECT a.CustomerID + 1, 'Dae', 'Kang'
		FROM customers as a 
		ORDER BY a.CustomerID DESC LIMIT 1;

SELECT * FROM customers
WHERE FirstName = 'Dae';

#Question 2b:
#Let's find the incorrect entry (let's just say, it was ID = 357).

SELECT * FROM customers
WHERE CustomerID = 357;

#Delete this record
DELETE FROM customers
WHERE CustomerID = 357;


#Question 2c:
#Let's say, that ID = 359 and ID = 695 got married, and ID = 359 took ID = 695's last name.

SELECT * FROM customers
WHERE CustomerID = 359 or CustomerID = 695;

UPDATE customers as a
JOIN customers AS b ON a.CustomerID = 359 AND b.CustomerID = 695
SET a.LastName = b.LastName;

SELECT * FROM customers
WHERE CustomerID = 359 or CustomerID = 695;


SELECT COUNT(*) FROM orders;

#Q3: Return a single table column of all customer's full name.
#Lets just concat First Name + Last Name

SELECT CONCAT(FirstName, ' ', LastName) as Full_Name
FROM customers;


#Q4: Top and bottom 5 customers, salespeople (employees?), countries, products
# How can we 'rate' these fields?
# We can sort customers by the amount of orders they make - more orders = 'better customer'
# We can sort employees if they are salespeople, and by the amount of orders they are assigned.
# Countries seem to relate to the employees table - so will be linked to employees.
# We can sort Products by the amount of times they appear in the Orders table - more instances = 'better product'

#Country - ranked based on number of orders managed by salespeople employees grouped by coutnry
SELECT country, COUNT(b.EmployeeID) as Orders_per_Country
FROM orders as a
JOIN employees as b USING (EmployeeID)
GROUP BY country
ORDER BY COUNT(b.EmployeeID) DESC;

SELECT * FROM orders
WHERE EmployeeID = 286 or EmployeeID = 288;

#Products - ranked based on the occurence of a certain product in the Orders Table
SELECT b.ProductName, COUNT(ProductID) as Most_popular_products
FROM orders as a
JOIN products as b USING (ProductID)
GROUP BY ProductName
ORDER BY COUNT(ProductID) DESC LIMIT 5;

#Customers - ranked by amount of orders they make.
SELECT CONCAT(b.FirstName, ' ', b.LastName) as Full_Name, COUNT(a.SalesOrderID) as Orders_Made
FROM orders as a
JOIN customers as b USING (CustomerID)
GROUP BY CONCAT(FirstName, ' ', LastName)
ORDER BY Orders_Made LIMIT 5;

SELECT COUNT(SalesOrderID) FROM orders
WHERE CustomerID = 827;

#Employees - ranked by amount of orders they are responsible for... and ARE NOT managers.
SELECT CONCAT(b.FirstName, ' ', b.LastName) as Full_Name, COUNT(EmployeeID) as Responsibility
FROM orders as a
JOIN employees as b USING (EmployeeID)
WHERE OrganizationLevel = 3
GROUP BY CONCAT(FirstName, ' ', LastName)
ORDER BY COUNT(ProductID) LIMIT 5;


#Question 5: amount of names starting with a in customers

SELECT COUNT(FirstName) as Starts_with_A FROM customers
WHERE FirstName LIKE 'a%';


# Q6: Make a useful Stored Procedure query...
# Product to Employee - what is the maximum List Price of items sold by a particular employee?

DELIMITER //

CREATE PROCEDURE MaxPriceItem_Sold(EmployeeID INT)
BEGIN
	SELECT CONCAT(e.FirstName, ' ', e.LastName) AS Full_Name, MAX(p.ListPrice) AS Maximum_Price_Item 
    FROM orders AS o
    JOIN products AS p USING (ProductID)
    JOIN employees AS e USING (EmployeeID)
    WHERE e.EmployeeID = EmployeeID
    GROUP BY CONCAT(e.FirstName, ' ', e.LastName);
END //

DELIMITER ;

#For the employeeID = 276...
CALL MaxPriceItem_Sold(276);


#Q8
CREATE TABLE changes_to_employee_log (
	LogID INT AUTO_INCREMENT PRIMARY KEY,
    EmployeeId INT NOT NULL,
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_fields VARCHAR(300) NOT NULL
);

DELIMITER //

CREATE TRIGGER trigger_employees_update
AFTER UPDATE ON Employees
FOR EACH ROW
BEGIN
	DECLARE changed_fields VARCHAR(300);
    SET changed_fields = '';
    
    IF OLD.ManagerID != NEW.ManagerID THEN
        SET changed_fields = CONCAT(changed_fields, 'ManagerID, ');
    END IF;

    IF OLD.JobTitle != NEW.JobTitle THEN
        SET changed_fields = CONCAT(changed_fields, 'JobTitle, ');
    END IF;

    IF OLD.OrganizationLevel != NEW.OrganizationLevel THEN
        SET changed_fields = CONCAT(changed_fields, 'OrganizationLevel, ');
    END IF;

    IF OLD.MaritalStatus != NEW.MaritalStatus THEN
        SET changed_fields = CONCAT(changed_fields, 'MaritalStatus, ');
    END IF;

    IF OLD.Country != NEW.Country THEN
        SET changed_fields = CONCAT(changed_fields, 'Country, ');
    END IF;

    -- Remove trailing comma and space from @changed_fields
    SET changed_fields = TRIM(TRAILING ', ' FROM changed_fields);

    -- Insert log into changes_to_employee_log table
    INSERT INTO changes_to_employee_log (EmployeeId, changed_fields)
    VALUES (OLD.EmployeeId, changed_fields);
    

END//

DELIMITER ;

#Test 1 - change an employee's marital status.
UPDATE employees
SET MaritalStatus = 'S' #was 'S'
WHERE EmployeeID = 277; #Jilian Carson

#Test 2 - change an employee's organization level, and JobTitle
UPDATE employees
SET OrganizationLevel = 2, JobTitle = 'Japanese Sales Manager'
WHERE EmployeeID = 281 ; #Shu Ito got a promotion!


SELECT * FROM employees;

SELECT * FROM changes_to_employee_log;

DROP TRIGGER IF EXISTS adventure_works.trigger_employees_update;
