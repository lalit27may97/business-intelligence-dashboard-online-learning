import pandas as pd
import numpy as np
from faker import Faker
import random
from datetime import datetime, timedelta

fake = Faker()
np.random.seed(42)

NUM_USERS = 10000
NUM_COURSES = 200

# -------------------------
# 1. USERS
# -------------------------
users = []
for i in range(NUM_USERS):
    user_type = np.random.choice(['Free', 'Paid'], p=[0.7, 0.3])
    signup_date = fake.date_between(start_date='-1y', end_date='today')

    users.append([
        i,
        fake.name(),
        random.randint(18, 50),
        fake.country(),
        signup_date,
        user_type
    ])

users_df = pd.DataFrame(users, columns=[
    'user_id','name','age','country','signup_date','user_type'
])

# -------------------------
# 2. COURSES
# -------------------------
categories = ['Data Science','Web Dev','AI','Business','Design']
difficulty = ['Beginner','Intermediate','Advanced']

courses = []
for i in range(NUM_COURSES):
    courses.append([
        i,
        f"Course_{i}",
        random.choice(categories),
        random.choice(difficulty),
        random.randint(0, 5000)
    ])

courses_df = pd.DataFrame(courses, columns=[
    'course_id','course_name','category','difficulty','price'
])

# -------------------------
# 3. ENROLLMENTS
# -------------------------
enrollments = []
enrollment_id = 0

for user_id in users_df['user_id']:
    num_courses = np.random.randint(1, 5)

    selected_courses = np.random.choice(courses_df['course_id'], num_courses, replace=False)

    for course_id in selected_courses:
        status = np.random.choice(
            ['Completed','Dropped','In Progress'],
            p=[0.3, 0.4, 0.3]
        )

        enrollments.append([
            enrollment_id,
            user_id,
            course_id,
            fake.date_between(start_date='-1y', end_date='today'),
            status
        ])

        enrollment_id += 1

enrollments_df = pd.DataFrame(enrollments, columns=[
    'enrollment_id','user_id','course_id','enrollment_date','completion_status'
])

# -------------------------
# 4. ACTIVITY (MOST IMPORTANT)
# -------------------------
activities = []
activity_id = 0

for _, row in enrollments_df.iterrows():
    user_id = row['user_id']
    course_id = row['course_id']
    start_date = row['enrollment_date']

    days_active = np.random.randint(5, 30)

    for d in range(days_active):
        current_date = start_date + timedelta(days=d)

        # Engagement decay
        base_watch = max(5, int(60 - d*2))

        # Weekend boost
        if current_date.weekday() >= 5:
            base_watch *= 1.5

        # Drop-off simulation
        if row['completion_status'] == 'Dropped' and d > 5:
            break

        activities.append([
            activity_id,
            user_id,
            course_id,
            current_date,
            int(base_watch),
            np.random.randint(0, 3),
            np.random.randint(1, 4)
        ])

        activity_id += 1

activity_df = pd.DataFrame(activities, columns=[
    'activity_id','user_id','course_id','date','watch_time','quiz_attempts','login_count'
])

# -------------------------
# 5. PAYMENTS
# -------------------------
payments = []
payment_id = 0

for _, user in users_df.iterrows():
    if user['user_type'] == 'Paid':
        num_payments = np.random.randint(1, 4)

        for _ in range(num_payments):
            payments.append([
                payment_id,
                user['user_id'],
                random.randint(500, 5000),
                fake.date_between(start_date=user['signup_date'], end_date='today')
            ])

            payment_id += 1

payments_df = pd.DataFrame(payments, columns=[
    'payment_id','user_id','amount','payment_date'
])

# -------------------------
# SAVE FILES
# -------------------------
users_df.to_csv('users.csv', index=False)
courses_df.to_csv('courses.csv', index=False)
enrollments_df.to_csv('enrollments.csv', index=False)
activity_df.to_csv('activity.csv', index=False)
payments_df.to_csv('payments.csv', index=False)

print("✅ All datasets generated successfully!")