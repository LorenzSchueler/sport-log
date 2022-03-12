insert into "user" (id, username, password, email) values 
    (1, 'user1', '$argon2id$v=19$m=4096,t=3,p=1$PurNCF1Y9tu+ETV/3yHSqA$mrMyoQ7YQbf+s9/30Bfma8VPlykLnC17dN2wG3zl9qc', 'email1'), -- "user1-passwd"
    (2, 'user2', '$argon2id$v=19$m=4096,t=3,p=1$PQlR/f+Tei/QCJdHoUOzKA$c8JnKvYFUkueiCxIIlNIHnCnpgIlqRtZ3v/Mip1v2kc', 'email2'), -- "user2-passwd"
    (3, 'user3', '$argon2id$v=19$m=4096,t=3,p=1$wT9O5qKLHQ2Z3+qKxx+wmg$GdEcLBbBOIqNDy/hdITV13FyvK2egPAG43bKB13cTsM', 'email3'); -- "user3-passwd"

insert into platform (id, name, credential) values 
    (1, 'wodify', true),
    (2, 'sportstracker', true);

insert into platform_credential (id, user_id, platform_id, username, password) values
    (1, 1, 1, 'woduser1', 'wodpasswd1'),
    (2, 2, 1, 'woduser2', 'wodpasswd2'),
    (3, 3, 2, 'stuser3', 'stpasswd3');

insert into action_provider (id, name, password, platform_id, description) values
    (1, 'wodify-login', '$argon2id$v=19$m=4096,t=3,p=1$NZeOJg1K37UlxV5wB7yFhg$C7HNfVK9yLZTJyvJNSOhvYRfUK+nGo1rz0lIck1aO6c', 1, 
        'Wodify Login can reserve spots in classes. The action names correspond to the class types.'), -- "wodify-login-passwd"
    (2, 'wodify-wod', '$argon2id$v=19$m=4096,t=3,p=1$FscunZHcMdL3To4Zxc5z5w$InsqwdstEFdkszaokG1rk0HS0oazMm4zTynD6pjQEgw', 1,  
        'Wodify Wod can fetch the Workout of the Day and save it in your wods. The action names correspond to the class type the wod should be fetched for.'), -- "wodify-wod-passwd"
    (3, 'sportstracker-fetch', '$argon2id$v=19$m=4096,t=3,p=1$mmRowryKPKBhRSvrRZRFmg$VPInpHpMq47ZEymwSojrst+CWVOoHopBlvSIwybchAg', 2,  
        'Sportstracker Fetch can fetch the latests workouts recorded with sportstracker and save them in your cardio sessions.'); -- "sportstracker-fetch-passwd"

insert into action (id, name, action_provider_id, description, create_before, delete_after) values 
    (1, 'CrossFit', 1, 'Reserve a spot in a CrossFit class.', 604800000, 0), 
    (2, 'Weightlifting', 1, 'Reserve a spot in a Weightlifting class.', 604800000, 0), 
    (3, 'Open Fridge', 1, 'Reserve a spot in a Open Fridge class.', 604800000, 0),
    (4, 'CrossFit', 2, 'Fetch and save the CrossFit wod for the current day.', 604800000, 0), 
    (5, 'Weightlifting', 2, 'Fetch and save the Weightlifting wod for the current day.', 604800000, 0), 
    (6, 'Open Fridge', 2, 'Fetch and save the Open Fridge wod for the current day.', 604800000, 0), 
    (7, 'fetch', 3, 'Fetch and save new workouts.', 604800000, 0);

insert into action_rule (id, user_id, action_id, weekday, time, enabled) values 
    (1, 1, 1, 'monday', '1970-01-01 09:00:00', true), 
    (2, 1, 3, 'tuesday', '1970-01-01 19:00:00', true),
    (3, 1, 4, 'monday', '1970-01-01 00:00:00', true),
    (4, 1, 4, 'tuesday', '1970-01-01 00:00:00', true),
    (5, 1, 4, 'wednesday', '1970-01-01 00:00:00', true),
    (6, 1, 4, 'thursday', '1970-01-01 00:00:00', true),
    (8, 1, 4, 'friday', '1970-01-01 00:00:00', true),
    (9, 1, 4, 'saturday', '1970-01-01 00:00:00', true),
    (10, 1, 4, 'sunday', '1970-01-01 00:00:00', true);

insert into action_event (id, user_id, action_id, datetime, enabled) values 
    (1, 1, 1, '2021-07-01 09:00:00', true), 
    (2, 1, 3, '2021-07-04 19:00:00', false), 
    (3, 2, 1, '2021-07-01 09:00:00', true), 
    (4, 2, 2, '2021-07-02 09:00:00', true), 
    (5, 2, 2, '2021-07-04 19:00:00', false),
    (6, 1, 4, '2021-08-29 00:00:00', true), 
    (7, 1, 4, '2021-08-30 00:00:00', true), 
    (8, 1, 7, '2021-07-01 09:00:00', true), 
    (9, 3, 7, '2021-07-01 11:00:00', true); 

insert into diary (id, user_id, date, bodyweight, comments) values
    (1, 1, '2021-08-20', 78.3, null),
    (2, 1, '2021-08-21', 78.8, null),
    (3, 1, '2021-08-22', 78.2, null),
    (4, 1, '2021-08-23', 77.9, null),
    (5, 1, '2021-08-24', 78.3, null);

insert into wod (id, user_id, date, description) values
    (1, 1, '2021-08-20', E'Strength:\nBack Squat 5*5\n\nFor Time (5 rounds):\n15 cal Ski Erg\n15 Dumbbell Snatch (45/30)'),
    (2, 1, '2021-08-21', E'Murph'),
    (3, 1, '2021-08-22', E'Cindy\n20 min AMRAP:\n5 Pull-Ups\n10 Push-Ups\n15 Air Squats'),
    (4, 1, '2021-08-23', E''),
    (5, 1, '2021-08-24', E'Deadlift 8x2\nSkill: Clean & Jerk');

insert into movement (id, user_id, name, description, movement_dimension, cardio) values
    (1, null, 'Back Squat', null, 'reps', false),
    (2, null, 'Front Squat', null, 'reps', false),
    (3, null, 'Over Head Squat', null, 'reps', false),
    (4, 1, 'Yoke Carry', null, 'distance', false),
    (5, null, 'Running', 'road running without significant altitude change', 'reps', true),
    (6, null, 'Trailrunning', null, 'reps', true),
    (7, null, 'Swimming Freestyle', 'indoor freestyle swimming', 'reps', true),
    (8, 1, 'Row Ergo', null, 'distance', true),
    (9, 1, 'Row Ergo', null, 'energy', true),
    (10, null, 'Pull-Up', null, 'reps', false),
    (11, null, 'Push-Up', null, 'reps', false),
    (12, null, 'Air Squat', null, 'reps', false);

insert into eorm (reps, percentage) values
    (1, 1.0),
    (2, 0.97),
    (3, 0.94),
    (4, 0.92),
    (5, 0.89),
    (6, 0.86),
    (7, 0.83),
    (8, 0.81),
    (9, 0.78),
    (10, 0.75),
    (11, 0.73),
    (12, 0.71),
    (13, 0.70),
    (14, 0.68),
    (15, 0.67),
    (16, 0.65),
    (17, 0.64),
    (18, 0.63),
    (19, 0.61),
    (20, 0.60),
    (21, 0.59),
    (22, 0.58),
    (23, 0.57),
    (24, 0.56),
    (25, 0.55),
    (26, 0.54),
    (27, 0.53),
    (28, 0.52),
    (29, 0.51),
    (30, 0.50);

insert into strength_session (id, user_id, datetime, movement_id, interval, comments) values
    (1, 1, '2021-08-20 16:00:00', 2, 120000, null),
    (2, 1, '2021-08-22 16:00:00', 1, null, null);

insert into strength_set (id, strength_session_id, set_number, count, weight) values
    (1, 1, 0, 5, 110),
    (2, 1, 1, 5, 115),
    (3, 1, 2, 5, 120),
    (4, 1, 3, 5, 122.5),
    (5, 1, 4, 5, 125),
    (6, 2, 0, 3, 125),
    (7, 2, 1, 3, 130),
    (8, 2, 2, 3, 135),
    (9, 2, 3, 3, 130);

insert into metcon (id, user_id, name, metcon_type, rounds, timecap, description) values
    (1, null, 'Cindy', 'amrap', null, 1200000, null),
    (2, null, 'Murph', 'for_time', 1, null, 'wear a weight vest (20/14) lbs'),
    (3, 1, '5k Row', 'for_time', 1, 1800000, null);

insert into metcon_movement (id, metcon_id, movement_id, distance_unit, movement_number, count, male_weight, female_weight) values
    (1, 1, 10, null, 0, 5, null, null),
    (2, 1, 11, null, 1, 10, null, null),
    (3, 1, 12, null, 2, 15, null, null),
    (4, 2, 5, null, 0, 1, 9, 6),
    (5, 2, 10, null, 1, 100, 9, 6),
    (6, 2, 11, null, 2, 200, 9, 6),
    (7, 2, 12, null, 3, 300, 9, 6),
    (8, 2, 5, null, 4, 1, 9, 6),
    (9, 3, 8, 'km', 0, 5, null, null);

insert into metcon_session (id, user_id, metcon_id, datetime, time, rounds, reps, rx, comments) values
    (1, 1, 1, '2020-08-20 16:00:00', null, 17, 8, true, null),
    (2, 1, 2, '2020-08-23 18:00:00', 1800000, null, null, false, 'without vest');

insert into route (id, user_id, name, distance, ascent, descent, track, marked_positions) values
    (1, 1, 'route 1X', 12456, 156, 149, null, null);

insert into cardio_session (id, user_id, movement_id, cardio_type, datetime, 
        distance, ascent, descent, time, calories, track, avg_cadence, 
        cadence, avg_heart_rate, heart_rate, route_id, comments) values
    (1, 1, 5, 'training', '2021-08-22 10:25:34', 
        26742, 35, 43, 9134000, null, null, 167, 
        null, 156, null, null, null);
