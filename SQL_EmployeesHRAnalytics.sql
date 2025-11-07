# Employees Dataset from MySQL 
#fixing errors
UPDATE titles
SET to_date = CONCAT('1999' , '-', MONTH(to_date), '-',  DAY(to_date))
WHERE to_date <> '9999-01-01' AND to_date LIKE '9999%';
-- -------------------------------------------------------------------->>>>>

# 1.the total number of employees in the company
SELECT COUNT(*) AS total_employees
FROM employees;
-- -------------------------------------------------------------------->>>>>
# 2.the average salary of employees in each department
SELECT d.dept_name, AVG(s.salary) AS avg_salary
FROM salaries s  
	#join salaries and dept_emp tables
JOIN dept_emp de ON de.emp_no = s.emp_no
				AND (s.to_date <= de.to_date
				AND s.from_date >= de.from_date)
	#join departments and dept_emp tables
JOIN departments d ON d.dept_no = de.dept_no
	#group by dept
GROUP BY dept_name
	#order by avg_salary by decending order
ORDER BY avg_salary DESC;
-- -------------------------------------------------------------------
#3. identify employees who are currently working in the company
SELECT *
FROM employees
	#filter out employees currently working
WHERE emp_no IN (
	SELECT emp_no
	FROM dept_emp
	WHERE to_date = '9999-01-01');
-- -------------------------------------------------------------------------------------------

#4. the highest-paid employee in the company
-- filter out employee who got max salary from salary table
SELECT 
	CONCAT(first_name, ' ', last_name) AS emp_name,
    (SELECT MAX(salary) FROM salaries) AS salary
FROM employees 
	#filter out who got maximum salary
WHERE emp_no IN (
	SELECT emp_no 
	FROM salaries 
	WHERE salary = (SELECT MAX(salary) FROM salaries));
-- >---------------------------------------------------------------->

#5- the top 5 highest-paid job titles
-- find max salary by each titles and order in descending order and limit 5
SELECT 
    t.title,
    MAX(s.salary) AS max_paid
FROM salaries s
	#join salaries and titles tables 
JOIN titles t ON s.emp_no = t.emp_no
				AND (s.from_date <= t.from_date
				AND s.to_date >= t.to_date)
	#group by title
GROUP BY t.title
	#order in descending 
ORDER BY max_paid DESC
	#limit the highest top 5 
LIMIT 5;
-- >-------------------------------------------------------------------

#6- the number of employees hired each year
-- count the number of employees by year from employees table
SELECT 
	year(hire_date) AS year, 
	COUNT(*) AS num_emp
FROM employees
GROUP BY year;
--  >----------------------------------------------------------------<

# the gender distribution of employees in each department
-- find count of male and female by department 
SELECT 
	d.dept_name, 
    SUM(CASE WHEN e.gender = 'M' THEN 1 END) AS num_male,  #count based on gender
    SUM(CASE WHEN e.gender = 'F' THEN 1 END) AS num_female  
FROM employees e
	#JOIN employees and dept_emp
JOIN  dept_emp de USING(emp_no)
	#JOIN departments and dept_emp
JOIN departments d USING (dept_no)
	#group by department
GROUP BY d.dept_name
	#order by number of males in descending
ORDER BY num_male DESC;
-- --------------------------------------------------------------------------------

#7- retrieve employees who have worked in multiple departments
-- filter out employees with more than one rows in dept_emp table
SELECT *
FROM employees
WHERE emp_no IN (
		#sub query to filter out mulltiple departments
	SELECT emp_no
	FROM dept_emp
		#group by emp_no
	GROUP BY emp_no
		#filter out number of departments greater than 1
	HAVING COUNT(dept_no) > 1
    );
-- ------------------------------------------------------------------

# 8-the most common job title in the company

-- find count of titles appeared  and order it in descending and limit 1
SELECT title, COUNT(*) AS title_count
FROM titles
	#group by title
GROUP BY title
	#order title count in descending orderr
ORDER BY title_count DESC
	#limit the max 
LIMIT 1;
-- ----------------------------------------------------------

# 9-calculate the total salary expense per department

-- join salaries, dept_emp, and departments 
-- find sum of salary by department and filter for the most recent 

SELECT 
	d.dept_name, 
	SUM(s.salary) AS total_salary_expense
FROM  dept_emp de
	#join dept_emp and departments 
JOIN departments d ON d.dept_no = de.dept_no
	#join dept_emp and salaries
JOIN salaries s ON de.emp_no = s.emp_no
	#filter for the most recent 
WHERE s.to_date = '9999-01-01'
	#group by departments
GROUP BY d.dept_name
	#order total salary expense in descending
ORDER BY total_salary_expense DESC;
-- ---------------------------------------------------------------
# ADVANCED 

#10- find the Department with the Highest Employee Retention Rate (employee retention rate per department (i.e., the percentage of employees who have not left the company))
-- find the number of employees who have not left the company and total employee in each department
-- amd rank retention rate and sort in decenting order and limit 1

#CTE:number of total emp and employees retained by department
WITH retained_emp AS (
	SELECT 
		dept_name,
			#the total num of employees
		COUNT(DISTINCT emp_no) AS total_num, 				 
			#the number of employees who have not left the company
		COUNT(CASE WHEN to_date = '9999-01-01' THEN emp_no END) AS  retained_num		
	FROM  dept_emp de 
		#join dept_emp and departments
	JOIN departments d ON de.dept_no = d.dept_no
		#group by department
	GROUP BY dept_name
)
#main query:find the max retention rate by department
SELECT 
	dept_name, 
    ROUND(100*retained_num/total_num,2) AS retention_rate
FROM retained_emp
	#rank retention rate by descending
ORDER BY retention_rate DESC
	#find the max
LIMIT 1;

-- --------------------------------------------------------------------------

#11- find Employees Who Had the Fastest Promotions

-- find the time taken for promotion and rank in ASCENDING orders
-- retrieve TOP 5 employees with the least time taken to promote
-- columns : emp_name, promo_title, prev_title, days_to_promote

#	CTE1; the time taken for promotion in days
WITH daydiff_promoted AS(
	SELECT 
		emp_no,
        title AS prev_title,
        LAG(title) OVER w AS promo_title,
		TIMESTAMPDIFF(day, LAG(from_date) OVER w, from_date) AS days_to_promote
	FROM titles
		#filter out employees who got promotions
	WHERE emp_no IN (
		SELECT emp_no FROM titles
		GROUP BY emp_no
		HAVING COUNT(title) > 1
		)
	WINDOW w AS (PARTITION BY emp_no ORDER BY from_date)
	),
	#CTE2; rank the time taken to promote in ASCENDING orders 
rankings AS(
	SELECT  *,
		RANK() OVER(ORDER BY days_to_promote) AS days_rank
    FROM daydiff_promoted 
		#remove null value from promo_title
    WHERE promo_title IS NOT NULL 
    )
	#Main query; retrieve TOP 5 employees with the least time taken 
SELECT
	CONCAT(e.first_name, ' ', e.last_name) AS emp_name,
	r.prev_title,
	r.promo_title,
    r.days_to_promote
FROM employees e
	#join employees and rankings 
JOIN rankings r ON e.emp_no = r.emp_no
	#top 5 fastest promotion
WHERE r.days_rank < 6;
-- --------------------------------------------------------------------------------
    
#12- the Salary Growth Rate for Each Employee Over Time

--  salary diff = current salary - previous salaries
--  salary growth rate : 100*salary diff/ previous salary
--  columns : emp_name, from_date, salary, prev_salary salary_growth_rate

	#CTE; salary growth rate of each emp over time
WITH salary_growth AS(
	SELECT 
		CONCAT(e.first_name, ' ', e.last_name) AS emp_name,
        LAG(s.salary) OVER w  AS prev_salary,
		s.salary AS curr_salary,
		s.from_date AS s_changed_date,
			#salary growth rate by employees
		ROUND(100*(s.salary - LAG(s.salary) OVER w) 
			/LAG(s.salary) OVER w, 2)	AS salary_growth_rate
	FROM employees e
        #join employees and salaries
	JOIN salaries s ON e.emp_no = s.emp_no
		#window - groupiing by employees and order by from_date ascending
	WINDOW w AS (PARTITION BY s.emp_no ORDER BY s.from_date)
)
	#main; retrieve data , removing null VALUES
SELECT *
FROM salary_growth
	#remove null values
WHERE prev_salary IS NOT NULL;

-- ----------------------------------------------------------------------------------------------

#13- Identify the Most Volatile Departments in Terms of Employee Turnover

-- find count of employees who left company by department and order  in decending order

SELECT 
	d.dept_name, 
    COUNT(*) AS turnover_count 
FROM departments d
JOIN dept_emp de ON de.dept_no = d.dept_no
	#filter out who who left company
WHERE de.to_date <> '9999-01-01'
	#group by department
GROUP BY dept_name
	#order turnover count in descending
ORDER BY turnover_count DESC
LIMIT 3;

-- --------------------------------------------------------------------------------
#14- Rank Employees by Salary within Their Department

-- find employees final salary who are currently working
-- and rank it in descending 
-- limit top 10 employees for each department

#cte; final salary of employees who are currently working and rank them
WITH emp_salary AS(
	SELECT 
		e.first_name, 
        d.dept_name,
        s.salary, 
        ROW_NUMBER() OVER(PARTITION BY d.dept_name ORDER BY s.salary DESC) AS salary_rank
	FROM salaries s
		#join salaries and dept_emp
	JOIN dept_emp de ON s.emp_no = de.emp_no
		#join departments and dept_emp
	JOIN departments d ON d.dept_no = de.dept_no
		#join salaries and employees
	JOIN employees e ON e.emp_no = s.emp_no AND s.to_date = '9999-01-01'
    )
SELECT *
FROM emp_salary
	#limit top 10 for each department
WHERE salary_rank <= 10;
-- --------------------------------------------------------------------------

# 15-Find the Longest-Serving Employees in the Company
-- find the tenure years from dept_emp table
-- RANK them in decending order 
-- filter for longest

#cte; the tenure years from dept_emp table
WITH served_years AS(
	SELECT 
		emp_no,
		TIMESTAMPDIFF(year,
			MIN(from_date), 
            CASE WHEN MAX(to_date) = '9999-01-01' THEN  NOW() 
				ELSE MAX(to_date) END)  AS tenure_years
	FROM dept_emp
	GROUP BY emp_no),
	#cte2;rank by tenure years
years_rnk AS (
	SELECT *, 
    DENSE_RANK() OVER(ORDER BY tenure_years DESC) AS rnk
    FROM served_years)
	#main; join above ctes and find the longest
SELECT 
	e.first_name,
    e.last_name, 
    r.tenure_years
FROM years_rnk r
JOIN employees e USING (emp_no)
	#filter out the longest for each department
WHERE rnk = 1;
-- ---------------------------------------------------------------------------

#16- Calculate the Average Time Employees Stay in a Department
-- find time stayed of each employee
-- and find average for each department

	#time stayed by employees 
 WITH time_stayed AS(
	SELECT 
		emp_no,
        dept_no,
			#time interval bet start date and final/current date
		TIMESTAMPDIFF(day,
					MIN(from_date), 
					CASE WHEN MAX(to_date) = '9999-01-01' THEN  NOW() 
						ELSE MAX(to_date) END)      AS stayed_days
	FROM dept_emp
	GROUP BY emp_no, dept_no
    ) 
	#main; avg_stayed years by department 
SELECT 
	dept_name,
    ROUND(AVG(stayed_days)/365, 2)  AS avg_stayed_years
FROM time_stayed
	#join cte:time_stayed and departments
JOIN departments USING (dept_no)
	#group by department
GROUP BY dept_name
ORDER BY avg_stayed_years DESC;
-- -------------------------------------------------------------------------------------------------------------------------------------
#17- Detect Salary Anomalies by Comparing with Department Average (Find employees whose salary is significantly lower or higher than their department's average salary.) 

-- find difference of salary from department average salary in % by year
-- compare whether it is above or below average

#18-find percentage of salary difference from avg salary of department by year
WITH salary_diff AS (
    SELECT 
		e.emp_no,
        e.first_name,
        e.last_name,
        d.dept_name, 
			#salary of employees by year
        s.salary, 
        YEAR(s.from_date) AS year,
			#average salary of each department by year
        AVG(s.salary) OVER w AS dept_avg,
			#percentage of salary difference from department's average salary by year
        (s.salary - AVG(s.salary) OVER w )*100/ AVG(s.salary) OVER w  AS diff_from_avg_perc
    FROM salaries s
		#join salaries and det_emp
    JOIN dept_emp de ON de.emp_no = s.emp_no
						AND s.from_date >= de.from_date
						AND s.to_date <= de.to_date
		#join departments and dept_emp
    JOIN departments d ON de.dept_no = d.dept_no
		#join employees and salaries
    JOIN employees e ON e.emp_no = s.emp_no
		#WINDOW : group by departments, years and order by year
    WINDOW w AS (PARTITION BY d.dept_name, YEAR(s.from_date) ORDER BY YEAR(s.from_date))
	)
	#main; check out above or below average 
SELECT *,
    CASE WHEN diff_from_avg_perc > 0 THEN 'Above Average'
		ELSE 'Below Average' END AS remark
FROM salary_diff
	#filter whose salaries are 50% greater or lower
WHERE ABS(diff_from_avg_perc) >= 50
	#order by diff of salary from avg in descending
ORDER BY diff_from_avg_perc DESC;

-- ---------------------------------------------------------------------------------------------------------------------------------------
#19- Identify Employees Who Have Received a Pay Cut
-- find salary change from time to time ; current salary and previous salary
-- find negative values of salary change

#cte1:salary change over time
WITH salary_alt AS(
	SELECT 
		emp_no,
		LAG(salary) OVER(PARTITION BY emp_no ORDER BY from_date) AS prev_salary,
		salary,
		from_date,
			#salary change from previous 
		salary - LAG(salary) OVER(PARTITION BY emp_no ORDER BY from_date) AS salary_change
FROM salaries 
)
#main: who has received pay cut?
SELECT 
	e.first_name,
    e.last_name,
    s.*
FROM salary_alt s
	#join cte;salry_alt and employees
JOIN employees e ON e.emp_no = s.emp_no
	#filter out where salary descreased
WHERE salary_change < 0
	#ORDER BY salary change in ascending
ORDER BY salary_change;

-- ----------------------------------------------------------------------------->>>
#20- Predict the Next Salary Increment for Employees Using Trend Analysis
# *Write a query to predict the next salary increase for employees based on their historical salary trends. Assume the increase follows a consistent pattern.)
-- find salary change ; current salary and previous salary
-- find average salary growth by employees in average intervals

#cte1; salary change of employees over time
WITH salary_alt AS(
	SELECT 
		emp_no,
        YEAR(from_date) AS curr_year,
        YEAR(LAG(from_date) OVER w)  AS prev_year,
		salary,
		LAG(salary) OVER w   AS prev_salary
	FROM salaries
		#retrieve employees currently working 
    WHERE emp_no IN (
		SELECT emp_no 
        FROM salaries 
        GROUP BY emp_no
        HAVING MAX(to_date) = '9999-01-01')
        #group and order for window function
    WINDOW w AS (PARTITION BY emp_no ORDER BY from_date) 
),
#cte2 ; avg salary growth and time interval by employees 
avg_growth AS (
	SELECT 
		emp_no,
		AVG(salary - prev_salary) AS avg_increase,
		AVG(curr_year - prev_year) AS avg_year_interval
    FROM salary_alt
		#remove null values
    WHERE prev_salary IS NOT NULL
    GROUP BY emp_no
)
#main; calculate predicted next salary
SELECT 
	g.emp_no,
    g.avg_increase,
	(	#corr_subquery: the final date 
		SELECT s.from_date
		FROM salaries s 
			#join salaries and avg_growth
		WHERE s.emp_no = g.emp_no 
		ORDER BY s.from_date DESC
		LIMIT 1
    ) + INTERVAL g.avg_year_interval YEAR 
    AS next_date,
    (	#corr_subquery: the final salary
		SELECT s.salary 
		FROM salaries s 
			#join salaries and avg_growth
		WHERE s.emp_no = g.emp_no 
		ORDER BY s.from_date DESC
		LIMIT 1
    ) + g.avg_increase 
    AS predited_salary
FROM avg_growth g;

-- --------------------------------------------------------------->>>
#21- Identify Departments with the Most Frequent Employee Transfers

-- find employees who transfered and cout them for each departments

SELECT 
	d.dept_name, 
    COUNT(*) AS num_emp_transfered
FROM dept_emp de
JOIN departments d ON d.dept_no = de.dept_no
	#filter emp who transfered
WHERE emp_no IN(
	SELECT emp_no
	FROM dept_emp
	GROUP BY emp_no
	HAVING COUNT(*) > 1)
	#group by department
GROUP BY dept_name
	#order by number of employees transferred in decending
ORDER BY num_emp_transfered DESC
LIMIT 3;

-- ---------------------------------------------------------------------------->>>

#22-Create a Stored Procedure to Analyze Employee Retention by Experience Level 
-- find experience level of each employee
-- find employees currently working 
-- rank retention rate and sort in decenting order
-- create store procedure
DROP PROCEDURE  IF EXISTS retention_by_experience;

DELIMITER $$
CREATE PROCEDURE retention_by_experience()
BEGIN 
	#cte1;experience level of each employee
	WITH  exp_level AS(
		SELECT 
			emp_no,
				 #assume current date = '2002-12-31'
			CASE WHEN TIMESTAMPDIFF(year, MIN(from_date), '2002-12-31') <= 2  THEN 'Entry'
				WHEN TIMESTAMPDIFF(year, MIN(from_date), '2002-12-31') <= 5  THEN 'Mid'
				WHEN TIMESTAMPDIFF(year, MIN(from_date),'2002-12-31') <= 10 THEN 'Senior'
				ELSE 'Executive' END AS experience_level
		FROM dept_emp
		GROUP BY emp_no
	),
    #cte2;find employees currently working 
	retained_emp AS (
		SELECT 
			el.experience_level,
				#total number of employees hired from company
			COUNT(DISTINCT el.emp_no) AS total_num, 	
				#the number of employees who have not left the company
			COUNT(CASE WHEN de.to_date = '9999-01-01' THEN 1 END) AS  retained_num		
		FROM  exp_level el
			#join cte1 and dept_emp 
		JOIN dept_emp de ON de.emp_no = el.emp_no
			#group by experience level
		GROUP BY experience_level
	)
	#rank retention rate and sort in decenting order
	SELECT 
		experience_level, 
		ROUND(100*retained_num/total_num,2) AS retention_rate
	FROM retained_emp
	ORDER BY retention_rate DESC;

END $$
DELIMITER ;

CALL retention_by_experience();

-- -------------------------------------------------------------------------------->>>>
#23- Compare the Gender Pay Gap Across Departments Using a UNION Query
-- find avg salary of each department for male and female
-- combine using UNION

#avg salary of male employees by department
SELECT 
	CONCAT(d.dept_name,'(M)') AS dept_name, 
    AVG(s.salary) avg_salary
FROM salaries s
	#join salaries and dept_emp
JOIN dept_emp de ON de.emp_no = s.emp_no
	#join dept_emp and department
JOIN departments d ON d.dept_no = de.dept_no
	#filter out male employees
WHERE de.emp_no IN(
	SELECT emp_no
    FROM employees
    WHERE gender = 'M'
    )
GROUP BY de.dept_no

UNION

#avg salary of female employees by department
SELECT 
	CONCAT(d.dept_name,'(F)') AS dept_name, 
    AVG(s.salary) AS avg_salary
FROM salaries s
	#join salaries and dept_emp
JOIN dept_emp de ON de.emp_no = s.emp_no
	#join dept_emp and departments
JOIN departments d ON d.dept_no = de.dept_no
	#filter out female employees
WHERE de.emp_no IN(
	SELECT emp_no
    FROM employees
    WHERE gender = 'F'
    )
GROUP BY de.dept_no
	#order by department name and avg salary
ORDER BY dept_name, avg_salary DESC;
-- ----------------------------------------------------------------------------------------------------------------->>

#24- Find Employees Who Consistently Received Below-Average Salaries in Their Career

-- find avg salary per department per year and find  employees with salary of below dept's avg
-- find count of below average and count of rows per employee
-- and filter when they are equal

# cte1:average salary by department by year and find below average salary by employee
WITH below_avg AS (
    SELECT 
		s.emp_no,
        d.dept_name, 
        s.salary,
        AVG(s.salary) OVER w AS dept_avg,
        CASE WHEN salary < AVG(s.salary) OVER w THEN 1 END AS below_average
    FROM salaries s
		#join salaries and dept_emp
    JOIN dept_emp de ON de.emp_no = s.emp_no
						AND s.from_date >= de.from_date
						AND s.to_date <= de.to_date
        #join dept_emp and departments
    JOIN departments d ON de.dept_no = d.dept_no
		#group and order for window funcs
    WINDOW w AS (PARTITION BY d.dept_name, YEAR(s.from_date) ORDER BY YEAR(s.from_date))
),
#cte2: consistantly below average salaries over time
below_avg_consistant AS(
	SELECT 	emp_no, dept_name
    FROM below_avg
		#group by emp and dept
	GROUP by emp_no, dept_name
		#filter when number of below_average rows = total rows 
    HAVING SUM(below_average) = COUNT(*)
    )
#main: employees who are consistantly paid salary below average 
SELECT 
	CONCAT(e.first_name,' ', e.last_name) AS emp_name,
    b.dept_name
FROM below_avg_consistant b
	#join cte2 and employees
JOIN employees e ON e.emp_no = b.emp_no;
--  -------------------------------------------------------------------------------------------------->>>

#25- Identify the Most Loyal Employees (Longest Tenure in Each Department)
-- find tenure years of each eamployees from dept_emp and
-- rank it with department partition in decending order of tenure years
-- filter rank less than 1

SELECT 
	e.emp_no,
    e.first_name,
    e.last_name,
    d.dept_name,
    t.tenure_years
FROM employees e
	#join employees and subquery
JOIN(
		#sub 1:tenure_years ranking
	SELECT
		emp_no, 
        dept_no,
        tenure_years,
        RANK() OVER (PARTITION BY dept_no ORDER BY tenure_years DESC) AS rnk
    FROM (
		#sub2:tenure years of each eamployees by dept_emp
		SELECT 
			emp_no,
            dept_no,
				#tenure years for all employees
            CASE WHEN MAX(to_date) = '9999-01-01' THEN TIMESTAMPDIFF(year, MIN(from_date), NOW())
				ELSE TIMESTAMPDIFF(year, MIN(from_date), MAX(to_date)) 
                END AS tenure_years
		FROM dept_emp
			#group by employees and departments
        GROUP BY emp_no,dept_no
	) AS tenured
    
) AS t ON t.emp_no = e.emp_no
    #join departments and sub1
JOIN departments d ON d.dept_no = t.dept_no
	#filter the longest tenure
WHERE rnk = 1;

-- ----------------------------------------------------------------------------->>>
#26- Find the Employees Who Had the Highest Salary Increase in a Single Promotion
-- find salary change of employees 
-- find employees who had promotion
-- combine them when dates of each are equal and sort it in decending orders 

#cte1; salary changes by employees over time
WITH salary_alt AS(
	SELECT 
		emp_no,
		salary,
		LAG(salary) OVER w AS prev_salary,
		from_date,
		to_date,
		salary - LAG(salary) OVER w AS salary_diff
	FROM salaries 
		#group and order for window functions
    WINDOW w AS (PARTITION BY emp_no ORDER BY from_date)
),
#cte2; salary increase by employees over time
salary_increase AS(
	SELECT *
	FROM salary_alt 
		#filter out only salary increase
	WHERE salary_diff > 0
),
#cte3;  employees with roll change
roll_change AS(
	SELECT 
		*,
		LAG(title) OVER(PARTITION BY emp_no ORDER BY from_date) AS prev_title
	FROM titles
		#filter out employees who received title change
    WHERE emp_no IN (
		SELECT emp_no
		FROM titles
		GROUP BY emp_no
		HAVING COUNT(*) > 1 ) 
)
#main; highest salary increase in each single promotion
SELECT 
	s.emp_no,
	CONCAT(e.first_name,' ', e.last_name) AS emp_name, 
    s.salary_diff AS salary_increase_amt,
    prev_title,
    rc.title
FROM salary_increase s
	#join cte2 and cte3 
JOIN roll_change rc ON s.emp_no = rc.emp_no 
						AND s.from_date = rc.from_date
	#join cte2 and employees
JOIN employees e ON e.emp_no = s.emp_no
	#order by salary diff in decending order
ORDER BY salary_diff DESC
	#limit top 5
LIMIT 5;

-- -------------------------------------------------------------------------------->>
#27- Find the Departments Where Average Salary Has Decreased Over Time
-- find avg salaries per department by year and compare current and previous avg salary 

#main: retrieve when current avg salary less than previous
SELECT *
FROM (
	#sub-query1 : compare current and previous avg salary
    SELECT 
		dept_name,
		`year`, 
		LAG(year) OVER(PARTITION BY dept_name ORDER BY `year`) AS prev_year,
		avg_salary,
		LAG(avg_salary) OVER(PARTITION BY dept_name ORDER BY year) AS prev_avg_salary
	FROM (
			#sub_query2: avg_salary by department and year
		SELECT 
			d.dept_name,
			YEAR(s.from_date) AS `year`, 
			AVG(s.salary) AS avg_salary
		FROM salaries s
			#join salaries and dept_emp
		JOIN dept_emp de ON de.emp_no = s.emp_no
						AND de.from_date <= s.from_date
						AND de.to_date >= s.to_date
			#join salaries and dept_emp
		JOIN departments d ON d.dept_no = de.dept_no
		GROUP BY 1,2
	) AS sub1
) as sub2
	#filter out where avg salary descreased over time
WHERE avg_salary < prev_avg_salary;

-- ------------------------------------------------------------------------------------>>>
# Identify Employees Who Had a Salary Decrease After a Role Change
-- find employees with salary decrease 
-- find employees who received roll change
-- combine them when dates of salary decrease and titles are equal

#cte1; salary changes of employees
WITH salary_alt AS(
	SELECT 
		emp_no,
		salary,
		LAG(salary) OVER w AS prev_salary,
		from_date,
		to_date,
			#salary change by employees 
		salary - LAG(salary) OVER w AS salary_change
	FROM salaries 
		##group and order for window functions
    WINDOW w AS (PARTITION BY emp_no ORDER BY from_date) 
),
#cte2; salary decrease by employees
salary_decrease AS(
	SELECT *
	FROM salary_alt 
		#filter out where salary decreeased
	WHERE salary_change < 0
),
#cte3; employees who recieved roll change
roll_change AS(
	SELECT 
		*,
		LAG(title) OVER(PARTITION BY emp_no ORDER BY from_date) AS prev_title
	FROM titles
		#filter out employees with more than one title
    WHERE emp_no IN (
		SELECT emp_no
		FROM titles
		GROUP BY emp_no
		HAVING COUNT(*) > 1 ) 
)
SELECT 
	s.emp_no,
	CONCAT(e.first_name,' ', e.last_name) AS emp_name, 
    s.salary_change,
    prev_title,
    rc.title
FROM salary_decrease s
	#join cte2 and cte3 
JOIN roll_change rc ON s.emp_no = rc.emp_no
						AND s.from_date = rc.from_date
	#join employees and cte2:salary_descrease
JOIN employees e ON e.emp_no = s.emp_no;

-- -------------------------------------------------------------------------------------------------->>>

#28- Identify the Top 3 Highest-Paid Employees in Each Department (Considering Salary History)
-- Find the average salary of employees over time by department
-- and rank it by decending order and limit  top 3

#avg salary by employee and department
WITH salary_avg AS( 
	SELECT 
		s.emp_no,
        de.dept_no,
        ROUND(AVG(salary),1) AS avg_salary
    FROM salaries s
		#join salaries and dept_emp
    JOIN dept_emp de
		ON s.emp_no = de.emp_no
			AND s.from_date >= de.from_date
            AND s.to_date <= de.to_date
		#group by emp and dept
	GROUP BY s.emp_no, de.dept_no
),
#rank by avg salary of each employee
salary_rank AS (
	SELECT 
		*,
        RANK() OVER(PARTITION BY dept_no ORDER BY avg_salary DESC) AS s_rank
	FROM salary_avg
)
#main query; top 3 salary employees by department
SELECT
	CONCAT(e.first_name, ' ' ,e.last_name) AS emp_name,
    d.dept_name,
    sr.avg_salary
FROM salary_rank sr
	#join cte and employees table
JOIN employees e 
	ON e.emp_no = sr.emp_no
	#join cte and  departments table to retrieve dept_name 
JOIN departments d
	ON d.dept_no = sr.dept_no
	#filter out top 3 salaries
WHERE s_rank < 4;



