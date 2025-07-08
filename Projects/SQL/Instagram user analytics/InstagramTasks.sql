/* A) MARKETING ANALYSIS */

/*Loyal user reward
	Objective: The marketing team wants to reward th emost loyal users, i.e.,the ones those ho have been using the plasform for the longest time.
    task: Identify the five oldest users in Instagram from the database.
*/
SELECT id, username, created_at
FROM users
ORDER BY created_at ASC
LIMIT 5;


/*Inactive user engagement
	Objective: The team wants to encourage inactive users by sending them promotional emails.
    task: Identify userswho have never posted a single photo,comment,like on instagram.
*/
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

/*Contest winner declaration
	Objective: The team has organised contest where the user with the most likes on a single photo posted by user
    Task: Determine the winner of the contest and provide the user,photo and like count details to the team
*/
SELECT photos.id AS photo_id, photos.image_url, photos.user_id, users.username, COUNT(likes.user_id) AS like_count
FROM photos
JOIN likes ON photos.id = likes.photo_id
JOIN users ON photos.user_id = users.id
GROUP BY photos.id
ORDER BY like_count DESC
LIMIT 1;

/*Hashtag research
	Objective: A partner brand wants to know the most pololar hashtags to reach the most people.
    Task: Identify and suggest the top five most commonly used hashtags on the platform. 
*/
SELECT tags.tag_name, COUNT(photo_tags.photo_id) AS usage_count
FROM tags
JOIN photo_tags ON tags.id =  photo_tags.tag_id
GROUP BY tags.id
ORDER BY usage_count DESC
LIMIT 5;

/*Ad Campaign lauch
	Objective: The team wants to knwo the best day of the week to launch ads.
    Task: Determine the day of the week when most users register on Instagram. Provide insights on when to schedule an ad campaign.
 */
 SELECT DAYNAME(created_at) AS day_of_week, COUNT(*) AS user_count
 FROM users
 GROUP BY day_of_week
 ORDER BY user_count DESC
 LIMIT 1;
 
/* B) INVESTOR METRICS */   

/*User Engagement
	Objective: Investors want to know if users are still active and posting on Instagram or if they are making fewer posts.
    Your task: calculate the average number of posts per user on instagram.
*/
SELECT(
	(SELECT COUNT(*) FROM photos)/(SELECT COUNT(*) FROM users)
    )AS average_posts_per_users;
    
/*Bots and fake accounts
	Objective: Investors want to know if the platform is crowded with fake and dummy accounts.
    Your task: Identify users (potential bots) who have liked every single every single photo on the site, as this is not typically possible for normal user.
*/    
SELECT u.id, u.username
FROM users u
WHERE (SELECT COUNT(*) FROM photos) = (SELECT COUNT(*) FROM likes l WHERE l.user_id = u.id);
    
    