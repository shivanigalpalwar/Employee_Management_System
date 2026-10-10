
CREATE DATABASE emp_management_system;
USE emp_management_system;

-- Table 1: Job Department
CREATE TABLE JobDepartment (
    Job_ID INT PRIMARY KEY,
    jobdept VARCHAR(50),
    name VARCHAR(100),
    description TEXT,
    salaryrange VARCHAR(50)
);

-- Table 2: Salary/Bonus
CREATE TABLE SalaryBonus (
    salary_ID INT PRIMARY KEY,
    Job_ID INT,
    amount DECIMAL(10,2),
    annual DECIMAL(10,2),
    bonus DECIMAL(10,2),
    CONSTRAINT fk_salary_job FOREIGN KEY (job_ID) REFERENCES JobDepartment(Job_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);
-- Table 3: Employee
CREATE TABLE Employee (
    emp_ID INT PRIMARY KEY,
    firstname VARCHAR(50),
    lastname VARCHAR(50),
    gender VARCHAR(10),
    age INT,
    contact_add VARCHAR(100),
    emp_email VARCHAR(100) UNIQUE,
    emp_pass VARCHAR(50),
    Job_ID INT,
    CONSTRAINT fk_employee_job FOREIGN KEY (Job_ID)
        REFERENCES JobDepartment(Job_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- Table 4: Qualification
CREATE TABLE Qualification (
    QualID INT PRIMARY KEY,
    Emp_ID INT,
    Position VARCHAR(50),
    Requirements VARCHAR(255),
    Date_In DATE,
    CONSTRAINT fk_qualification_emp FOREIGN KEY (Emp_ID)
        REFERENCES Employee(emp_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Table 5: Leaves
CREATE TABLE Leaves (
    leave_ID INT PRIMARY KEY,
    emp_ID INT,
    date DATE,
    reason TEXT,
    CONSTRAINT fk_leave_emp FOREIGN KEY (emp_ID) REFERENCES Employee(emp_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table 6: Payroll
CREATE TABLE Payroll (
    payroll_ID INT PRIMARY KEY,
    emp_ID INT,
    job_ID INT,
    salary_ID INT,
    leave_ID INT,
    date DATE,
    report TEXT,
    total_amount DECIMAL(10,2),
    CONSTRAINT fk_payroll_emp FOREIGN KEY (emp_ID) REFERENCES Employee(emp_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_job FOREIGN KEY (job_ID) REFERENCES JobDepartment(job_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_salary FOREIGN KEY (salary_ID) REFERENCES SalaryBonus(salary_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_leave FOREIGN KEY (leave_ID) REFERENCES Leaves(leave_ID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

Select * from employee;
SELECT * FROM jobdepartment;
SELECT * FROM leaves;
SELECT * FROM payroll;
SELECT * FROM qualification;
SELECT * FROM salarybonus;

# 1. EMPLOYEE INSIGHTS
# ●	How many unique employees are currently in the system?
SELECT 
    COUNT(DISTINCT emp_ID) AS unique_employees_count
FROM
    employee;
    
-- subquery
SELECT COUNT(*) AS unique_employees_count
FROM (
    SELECT DISTINCT emp_ID
    FROM Employee
) AS unique_emp;

SELECT DISTINCT emp_ID
    FROM Employee;
    
# ●	Which departments have the highest number of employees?
SELECT 
    jd.jobdept AS department, COUNT(e.emp_id) AS emp_count
FROM
    employee AS e
        JOIN
    jobdepartment AS jd ON e.Job_ID = jd.Job_ID
GROUP BY jd.jobdept
ORDER BY emp_count DESC;

# ●	What is the average salary per department?
SELECT 
    jd.jobdept AS department, AVG(s.amount) AS avg_salary
FROM
    salarybonus AS s
        JOIN
    jobdepartment AS jd ON jd.Job_ID = s.Job_ID
GROUP BY jd.jobdept
ORDER BY avg_salary DESC;

# ●	Who are the top 5 highest-paid employees?
SELECT 
    e.emp_ID,
    CONCAT(e.firstname, ' ', e.lastname) AS employee_name,
    s.amount AS salary
FROM
    employee AS e
        JOIN
    salarybonus AS s ON e.Job_ID = s.Job_ID
ORDER BY salary DESC
LIMIT 5;

-- CTE + WINDOW FUNCTION + JOIN
WITH ranked_employees AS (
    SELECT
        e.emp_ID,
        CONCAT(e.firstname, ' ', e.lastname) AS employee_name,
        s.amount AS salary,
        ROW_NUMBER() OVER (ORDER BY s.amount DESC) AS salary_rank
    FROM Employee e
    JOIN SalaryBonus s
        ON e.Job_ID = s.Job_ID
)
SELECT emp_ID,
       employee_name,
       salary
FROM ranked_employees
WHERE salary_rank <= 5
ORDER BY salary_rank;

# ●	What is the total salary expenditure across the company?
SELECT 
    SUM(amount) AS total_salary_expenditure
FROM
    salarybonus;
    
-- STORED PROCEDURE

DELIMITER $$
CREATE PROCEDURE GetTotalSalaryExpenditure()
BEGIN
    SELECT SUM(amount) AS total_salary_expenditure
    FROM SalaryBonus;
END $$
DELIMITER ;

CALL GetTotalSalaryExpenditure();
    
    
    # 2. JOB ROLE AND DEPARTMENT ANALYSIS
# ●	How many different job roles exist in each department?
SELECT 
    jobdept AS department, COUNT(DISTINCT name) AS role_count
FROM
    jobdepartment
GROUP BY jobdept
ORDER BY role_count DESC;

# ●	What is the average salary range per department?
SELECT 
    jd.jobdept AS department,
    AVG((CAST(REPLACE(TRIM(SUBSTRING_INDEX(jd.salaryrange, '-', 1)),
            '$',
            '')
        AS DECIMAL (10 , 2 )) + CAST(REPLACE(TRIM(SUBSTRING_INDEX(jd.salaryrange, '-', - 1)),
            '$',
            '')
        AS DECIMAL (10 , 2 ))) / 2) AS avg_salary_range
FROM
    jobdepartment AS jd
GROUP BY jd.jobdept;

# ●	Which job roles offer the highest salary?
SELECT 
    jd.name AS job_role, s.amount AS salary
FROM
    jobdepartment AS jd
        JOIN
    salarybonus AS s ON jd.Job_ID = s.Job_ID
ORDER BY salary DESC
LIMIT 1;

# ●	Which departments have the highest total salary allocation?
SELECT 
    jd.jobdept AS department, SUM(s.amount) AS total_salary
FROM
    jobdepartment jd
        JOIN
    salarybonus s ON jd.Job_ID = s.Job_ID
GROUP BY jd.jobdept
ORDER BY total_salary DESC;

# 3. QUALIFICATION AND SKILLS ANALYSIS
# ●	How many employees have at least one qualification listed?
SELECT 
    COUNT(DISTINCT EMP_ID) AS emp_with_qualifications
FROM
    qualification;
    
-- EXISTS()
SELECT COUNT(*) AS emp_with_qualifications
FROM Employee e
WHERE EXISTS (
    SELECT 1
    FROM Qualification q
    WHERE q.Emp_ID = e.emp_ID
);


# ●	Which positions require the most qualifications?
SELECT 
    position, COUNT(*) AS qualification_count
FROM
    qualification
GROUP BY position
ORDER BY qualification_count DESC;

# ●	Which employees have the highest number of qualifications?
SELECT 
    e.emp_ID,
    CONCAT(e.firstname, ' ', e.lastname) AS emp_name,
    COUNT(q.QualID) AS qualification_count
FROM
    employee e
        JOIN
    qualification q ON e.emp_ID = q.EMP_ID
GROUP BY e.emp_id , e.firstname , e.lastname
ORDER BY qualification_count DESC;

-- CTE+ AGGREGATE+ SUB QUERY
WITH employee_qualifications AS (
    SELECT
        e.emp_ID,
        CONCAT(e.firstname, ' ', e.lastname) AS employee_name,
        COUNT(q.QualID) AS qualification_count
    FROM Employee e
    JOIN Qualification q
        ON e.emp_ID = q.Emp_ID
    GROUP BY e.emp_ID, e.firstname, e.lastname
)
SELECT emp_ID,
       employee_name,
       qualification_count
FROM employee_qualifications
WHERE qualification_count = (
    SELECT MAX(qualification_count)
    FROM employee_qualifications
);

# 4. LEAVE AND ABSENCE PATTERNS
# ●	Which year had the most employees taking leaves?
SELECT 
    YEAR(date) AS Leave_year,
    COUNT(DISTINCT emp_ID) AS employees_on_leave
FROM
    leaves
GROUP BY YEAR(date)
ORDER BY employees_on_leave DESC;

# ●	What is the average number of leave days taken by its employees per department?
SELECT 
    jd.jobdept AS department, AVG(leave_count) AS avg_leave_days
FROM
    (SELECT 
        e.emp_ID, e.job_ID, COUNT(l.leave_ID) AS leave_count
    FROM
        employee e
    LEFT JOIN leaves l ON e.emp_ID = l.emp_ID
    GROUP BY e.emp_id , e.job_id) AS employee_leaves
        JOIN
    jobdepartment jd ON employee_leaves.Job_ID = jd.Job_ID
GROUP BY jd.jobdept
ORDER BY avg_leave_days DESC;

# ●	Which employees have taken the most leaves?
SELECT 
    e.emp_ID,
    CONCAT(e.firstname, ' ', e.lastname) AS emp_name,
    COUNT(l.leave_ID) AS leave_count
FROM
    employee e
        JOIN
    leaves l ON e.emp_ID = l.emp_ID
GROUP BY e.emp_ID , e.firstname , e.lastname
ORDER BY leave_count DESC;

-- DERIVED TABLE + SUBQUERY + AGGREGATE
SELECT emp_ID,
       employee_name,
       leave_count
FROM (
    SELECT
        e.emp_ID,
        CONCAT(e.firstname, ' ', e.lastname) AS employee_name,
        COUNT(l.leave_ID) AS leave_count
    FROM Employee e
    JOIN Leaves l
        ON e.emp_ID = l.emp_ID
    GROUP BY e.emp_ID, e.firstname, e.lastname
) AS employee_leaves
WHERE leave_count = (
    SELECT MAX(leave_count)
    FROM (
        SELECT COUNT(leave_ID) AS leave_count
        FROM Leaves
        GROUP BY emp_ID
    ) AS leave_counts
);

# ●	What is the total number of leave days taken company-wide?
SELECT 
    COUNT(*) AS total_leave_days
FROM
    Leaves;

# ●	How do leave days correlate with payroll amounts?

SELECT l.emp_ID,
       COUNT(l.leave_ID) AS leave_days,
       SUM(p.total_amount) AS payroll_amount
FROM Leaves l
JOIN Payroll p
    ON l.emp_ID = p.emp_ID
GROUP BY l.emp_ID;


WITH leave_data AS (
    SELECT emp_ID,
           COUNT(leave_ID) AS leave_days
    FROM Leaves
    GROUP BY emp_ID
),
payroll_data AS (
    SELECT emp_ID,
           SUM(total_amount) AS payroll_amount
    FROM Payroll
    GROUP BY emp_ID
),
employee_data AS (
    SELECT l.emp_ID,
           l.leave_days,
           p.payroll_amount
    FROM leave_data l
    JOIN payroll_data p
        ON l.emp_ID = p.emp_ID
)
SELECT
(
    SUM(leave_days * payroll_amount)
    - (SUM(leave_days) * SUM(payroll_amount) / COUNT(*))
)
/
SQRT(
    (SUM(leave_days * leave_days)
     - POWER(SUM(leave_days), 2) / COUNT(*))
    *
    (SUM(payroll_amount * payroll_amount)
     - POWER(SUM(payroll_amount), 2) / COUNT(*))
)
AS correlation
FROM employee_data;

# 5. PAYROLL AND COMPENSATION ANALYSIS
# ●	What is the total monthly payroll processed?
SELECT DATE_FORMAT(date, '%m') AS month,
       SUM(total_amount) AS total_monthly_payroll
FROM Payroll
GROUP BY DATE_FORMAT(date, '%m')
ORDER BY month;

-- STORED PROCEDURE WITH INPUT PARAMETER

DELIMITER $$
CREATE PROCEDURE GetMonthlyPayroll(IN payroll_month INT)
BEGIN
    SELECT
        MONTHNAME(date) AS month,
        SUM(total_amount) AS total_monthly_payroll
    FROM Payroll
    WHERE MONTH(date) = payroll_month
    GROUP BY MONTH(date), MONTHNAME(date);
END $$
DELIMITER ;

CALL GetMonthlyPayroll(3);

CALL GetMonthlyPayroll(4);

# ●	What is the average bonus given per department?
SELECT jd.jobdept AS department,
       AVG(sb.bonus) AS average_bonus
FROM SalaryBonus sb
JOIN JobDepartment jd
    ON sb.Job_ID = jd.Job_ID
GROUP BY jd.jobdept
ORDER BY average_bonus DESC;

 # ●	Which department receives the highest total bonuses?
SELECT jd.jobdept AS department,
       SUM(sb.bonus) AS total_bonus
FROM SalaryBonus sb
JOIN JobDepartment jd
    ON sb.Job_ID = jd.Job_ID
GROUP BY jd.jobdept
ORDER BY total_bonus DESC;

# ●	What is the average value of total_amount after considering leave deductions?
SELECT AVG(total_amount) AS average_total_amount
FROM Payroll
WHERE leave_ID IS NOT NULL;




