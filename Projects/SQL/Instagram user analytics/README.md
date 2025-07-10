# 📸 Instagram User Analytics (SQL Project)

This project uses MySQL to perform data analysis on an Instagram-like platform. It focuses on real-world business use cases — like user loyalty, engagement, hashtag research, and bot detection — helping teams make data-driven decisions.

---

## 🧩 Data Schema Overview

The database `ig_clone` includes:

| Table         | Description                                           |
|---------------|-------------------------------------------------------|
| `users`       | User accounts with signup timestamps                  |
| `photos`      | Posts made by users                                   |
| `comments`    | Comments made by users on photos                      |
| `likes`       | Likes on photos by users                              |
| `follows`     | Follower/followee relationships between users         |
| `tags`        | Hashtags                                              |
| `photo_tags`  | Mapping of tags to photos (many-to-many relationship) |

---

## ✅ Business Use Cases & Queries

### 🅰️ MARKETING ANALYSIS

---

### 📌 Loyal User Reward

**Objective**: Identify and reward the longest-standing users on the platform.

**Query**:
```sql
SELECT id, username, created_at
FROM users
ORDER BY created_at ASC
LIMIT 5;
```
**Explanation:**
Sorts users by signup date (ascending) and returns the first five. Helps identify early adopters or loyal users.


### 📌 Inactive User Engagement
**Objective:** Find users who haven't interacted with the platform in a long time and send them promotional emails.

```sql
SELECT 
    u.id,
    u.username,
    u.created_at,
    
    -- Last photo posted
    (SELECT MAX(p2.created_dat)
     FROM photos p2
     WHERE p2.user_id = u.id) AS last_photo_date,
     
    -- Last comment made
    (SELECT MAX(c2.created_at)
     FROM comments c2
     WHERE c2.user_id = u.id) AS last_comment_date,
     
    -- Last like made
    (SELECT MAX(l2.created_at)
     FROM likes l2
     WHERE l2.user_id = u.id) AS last_like_date

FROM users u

-- Get latest engagement date across all users
CROSS JOIN (
    SELECT GREATEST(
        COALESCE((SELECT MAX(created_dat) FROM photos), '1000-01-01'),
        COALESCE((SELECT MAX(created_at) FROM comments), '1000-01-01'),
        COALESCE((SELECT MAX(created_at) FROM likes), '1000-01-01')
    ) AS max_activity_date
) AS latest

-- Filter out users who were active in the last 60 days (based on max_activity_date)
LEFT JOIN photos p 
    ON u.id = p.user_id AND p.created_dat >= latest.max_activity_date - INTERVAL 60 DAY
LEFT JOIN comments c 
    ON u.id = c.user_id AND c.created_at >= latest.max_activity_date - INTERVAL 60 DAY
LEFT JOIN likes l 
    ON u.id = l.user_id AND l.created_at >= latest.max_activity_date - INTERVAL 60 DAY

WHERE p.id IS NULL AND c.id IS NULL AND l.photo_id IS NULL;
```

**Explanation:**
This query identifies users with no recent posts, likes, or comments within the last 60 days of the most recent activity date in the database. It uses subqueries and joins, and replaces NOW() with a snapshot of actual latest activity.

### 📌 Contest Winner Declaration
**Objective:** Determine the user who received the most likes on a single photo.

```sql
SELECT photos.id AS photo_id, photos.image_url, photos.user_id, users.username, COUNT(likes.user_id) AS like_count
FROM photos
JOIN likes ON photos.id = likes.photo_id
JOIN users ON photos.user_id = users.id
GROUP BY photos.id
ORDER BY like_count DESC
LIMIT 1;
```

**Explanation:**
Ranks all photos by number of likes and returns the most liked one — useful for declaring contest winners.

### 📌 Hashtag Research
**Objective:** Find the top 5 most-used hashtags for marketing insights.

```sql
SELECT tags.tag_name, COUNT(photo_tags.photo_id) AS usage_count
FROM tags
JOIN photo_tags ON tags.id =  photo_tags.tag_id
GROUP BY tags.id
ORDER BY usage_count DESC
LIMIT 5;
```
**Explanation:**
Identifies the most popular tags based on usage frequency — ideal for hashtag strategy.

### 📌 Ad Campaign Launch
**Objective:** Determine the best day of the week to launch marketing ads.

```sql
 SELECT DAYNAME(created_at) AS day_of_week, COUNT(*) AS user_count
 FROM users
 GROUP BY day_of_week
 ORDER BY user_count DESC
 LIMIT 1;
```

**Explanation:**
Analyzes which weekday sees the highest user registrations — useful for timing ad campaigns.

### 🅱️ INVESTOR METRICS

### 📌 User Engagement
**Objective:** Help investors understand if users are still posting actively.

```sql
SELECT(
    (SELECT COUNT(*) FROM photos) / 
    (SELECT COUNT(*) FROM users)
) AS average_posts_per_users;
```
**Explanation:**
Calculates the average number of posts per user. A lower number over time could indicate a decline in engagement.

### 📌 Bots and Fake Accounts Detection
**Objective:** Detect users who behave like bots — e.g., liking **every single photo**, which is unlikely for real users.

```sql
SELECT u.id, u.username
FROM users u
WHERE (SELECT COUNT(*) FROM photos) = 
      (SELECT COUNT(*) FROM likes l WHERE l.user_id = u.id);
```
**Explanation:**
Flags users whose like count matches the total number of photos on the platform — a common bot behavior pattern.
