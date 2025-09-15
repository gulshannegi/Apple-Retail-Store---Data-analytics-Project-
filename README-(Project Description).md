Advanced SQL analysis of Apple retail sales data.
This project demonstrates the ability to work with complex datasets, apply advanced SQL functions, optimize queries, and solve real-world business problems to extract actionable insights.

---

## 📌 Project Overview
This project analyzes Apple retail sales and warranty claim data, uncovering insights into store performance, product trends, and customer behavior .  
Key highlights include:
- Multi-year sales analysis
- Warranty claim probability and rejection analysis
- Product lifecycle sales trends
- Year-over-year growth tracking
- Performance optimization using indexing 

---

## 🗂️ Database Schema
The dataset consists of five main tables:
- **stores** → Information about Apple stores (ID, name, city, country)  
- **category** → Product categories (ID, name)  
- **products** → Product details (ID, name, launch date, price)  
- **sales** → Transactions (sale date, store ID, product ID, quantity)  
- **warranty** → Warranty claims (claim date, repair status)  

👉 See `schema.sql` for table definitions.

---

## Business Questions Solved
- Category with most warranty claims in the last two years  
- Probability of warranty claims after purchase (by country)  
- Yearly growth ratio for each store  
- Correlation between product price and warranty claims  
- Store with highest % of “Paid Repaired” claims  
- Monthly running totals of sales and trend comparison  
- Product lifecycle sales segmentation  

---

## Key Skills Demonstrated
- **Time-Based Analysis**: Monthly sales tracking, multi-year performance, and lifecycle segmentation  
- **Window Functions**: Running totals, year-over-year (YoY) growth, lag/lead comparisons, and ranking  
- **Complex Joins & Aggregations**: Identifying least-selling products, top categories, and unit trends  
- **Correlation & Segmentation**: Analyzing product price vs. warranty claims and lifecycle-based sales trends

## ❓ Key Business Questions Solved
- Which store sold the most units in the past year?  
- What is the least-selling product in each country each year?  
- How many warranty claims were filed within 180 days of purchase?  
- What % of warranty claims were rejected?  
- Which product category had the most claims in the last 2 years?  
- What is the monthly running total of sales for each store (last 4 years)?  
- What is the YoY growth ratio for each store?  
- What is the probability of warranty claims after purchase (by country)?  
- How do sales vary across the product lifecycle (0–6, 6–12, 12–18, 18+ months)?

---

This project focused on solving real-world business problems with SQL:
- Analyzed over **1M rows** of Apple retail data  
- Generated insights on **sales trends, warranty claims, product lifecycle performance, and growth patterns**  
- Demonstrated the impact of **query optimization** for large datasets  

