-- Demo data. Run after schema.sql.
-- Emergency contacts: owned by Sanjay.
-- Recommendations: owned by Vishwa.

-- ============================================================
-- Emergency contacts — default helplines
-- ============================================================
-- These must stay visible even when Overpass returns nothing (REQ-5.3).
-- region is null: these apply nationwide, not to one destination.

insert into emergency_contacts (region, service_name, phone_number, is_default) values
  (null, 'All-purpose emergency', '112', true),
  (null, 'Police', '100', true),
  (null, 'Ambulance', '108', true),
  (null, 'Fire', '101', true),
  (null, 'Women helpline', '1091', true),
  (null, 'Tourist helpline', '1363', true);

-- ============================================================
-- Recommendations — example rows
-- ============================================================
-- Real place names, not "Restaurant 1" / "Restaurant 2" — a placeholder
-- name looks exactly like what it is.

insert into recommendations
  (destination, name, category, description, rating, price_level, tags, latitude, longitude, image_url)
values
  ('Goa', 'Britto''s', 'restaurant',
   'Beachfront restaurant on Baga Beach known for seafood and Goan curries.',
   4.3, 2, array['seafood', 'beachfront', 'goan'], 15.5553, 73.7517, null),
  ('Goa', 'Fort Aguada', 'attraction',
   '17th-century Portuguese fort with a lighthouse overlooking the Arabian Sea.',
   4.5, 1, array['historical', 'viewpoint'], 15.4925, 73.7738, null);

-- TODO (Vishwa): add the remaining 10-15 places per destination, across
-- 3-5 chosen destinations. Keep names real and specific — pull from actual
-- listings, not generated placeholders.
