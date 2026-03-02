#!/usr/bin/env python3
"""
Generate realistic seed data for Analytics Engineering Assessment.
Creates ~1,000 orders, ~100 customers, ~50 products with intentional data quality issues.
"""

import csv
import random
from datetime import datetime, timedelta

random.seed(42)

# Products: 50 items across categories
categories = ['Electronics', 'Books', 'Home', 'Office', 'Apparel', 'Sports']
products = []
for i in range(1, 51):
    category = random.choice(categories)
    price = round(random.uniform(9.99, 299.99), 2)
    products.append({
        'product_id': f'prod_{i:03d}',
        'name': f'{category} Product {i}',
        'category': category,
        'unit_price': price
    })

# Customers: 100 customers with some duplicates to test
emails = []
customers = []
for i in range(1, 101):
    country = random.choice(['US', 'UK', 'CA', 'DE', 'FR', 'AU', 'JP'])
    created = datetime(2023, 1, 1) + timedelta(days=random.randint(0, 365))
    # Occasionally duplicate email (data quality issue)
    if i > 90 and random.random() < 0.3:
        email = emails[random.randint(0, len(emails)-1)]
    else:
        email = f'customer{i}@example.com'
    emails.append(email)
    customers.append({
        'customer_id': f'cust_{i:03d}',
        'email': email,
        'country': country,
        'created_at': created.strftime('%Y-%m-%d')
    })

# Orders: ~1,000 orders with quality issues
orders = []
base_date = datetime(2024, 1, 1)
statuses = ['completed', 'pending', 'cancelled', 'shipped', 'refunded']

for i in range(1, 1001):
    customer_id = f'cust_{random.randint(1, 100):03d}'
    # Random date across 90 days with some bad dates
    if random.random() < 0.02:  # 2% bad dates
        order_date = 'invalid_date'
    elif random.random() < 0.02:  # 2% future dates
        order_date = (base_date + timedelta(days=random.randint(100, 200))).strftime('%Y-%m-%d')
    elif random.random() < 0.02:  # 2% very old dates
        order_date = '2020-01-01'
    else:
        order_date = (base_date + timedelta(days=random.randint(0, 90))).strftime('%Y-%m-%d')
    
    status = random.choice(statuses)
    
    # Null total_amount for some pending orders - output NULL not empty string
    if status == 'pending' and random.random() < 0.1:
        total_amount = 'NULL'  # Will be read as null
    elif status == 'cancelled' and random.random() < 0.3:
        total_amount = round(random.uniform(0, 0.01), 2)  # Near-zero cancelled
    else:
        total_amount = round(random.uniform(15, 500), 2)
    
    # Updated_at for incremental logic (randomly 0-30 days after order)
    updated_days = random.randint(0, 30)
    if order_date != 'invalid_date' and not order_date.startswith('20'):
        updated_at = order_date
    else:
        try:
            dt = datetime.strptime(order_date, '%Y-%m-%d') + timedelta(days=updated_days)
            updated_at = dt.strftime('%Y-%m-%d')
        except:
            updated_at = order_date
    
    orders.append({
        'order_id': f'ord_{i:04d}',
        'customer_id': customer_id,
        'order_date': order_date,
        'status': status,
        'total_amount': total_amount,
        'currency': 'USD',
        'updated_at': updated_at
    })

# Add intentional duplicates (same order_id, different data - data quality issue)
dup_order = orders[500].copy()
dup_order['total_amount'] = round(float(dup_order['total_amount']) * 2, 2) if dup_order['total_amount'] != 'NULL' else 99.99
orders.append(dup_order)

# Write CSVs with NULL handling
with open('seeds/products.csv', 'w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['product_id', 'name', 'category', 'unit_price'])
    writer.writeheader()
    writer.writerows(products)

with open('seeds/customers.csv', 'w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['customer_id', 'email', 'country', 'created_at'])
    writer.writeheader()
    writer.writerows(customers)

with open('seeds/orders.csv', 'w', newline='') as f:
    # Custom write to handle NULL values properly
    writer = csv.writer(f)
    writer.writerow(['order_id', 'customer_id', 'order_date', 'status', 'total_amount', 'currency', 'updated_at'])
    for order in orders:
        writer.writerow([
            order['order_id'],
            order['customer_id'],
            order['order_date'],
            order['status'],
            order['total_amount'] if order['total_amount'] != 'NULL' else '',
            order['currency'],
            order['updated_at']
        ])

print(f"Generated {len(products)} products, {len(customers)} customers, {len(orders)} orders")
print("Data quality issues added:")
print("  - ~6% bad dates (invalid, future, very old)")
print("  - ~10% pending orders with null amounts")
print("  - ~30% cancelled orders with near-zero amounts")
print("  - Some duplicate emails in customers")
print("  - One duplicate order_id with different data")
print("  - Added updated_at for incremental logic")
