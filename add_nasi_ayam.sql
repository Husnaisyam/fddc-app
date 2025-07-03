-- Add nasi ayam to food_categories if it doesn't exist
INSERT INTO food_categories (name, description)
SELECT 'nasi ayam', 'A traditional Malaysian dish of fragrant chicken rice, often served with flavorful chicken and accompanied by chili sauce'
WHERE NOT EXISTS (SELECT * FROM food_categories WHERE name = 'nasi ayam');

-- Add nutritional information for nasi ayam to food_info
INSERT INTO food_info (food_category_id, calories, protein, carbs, fats, description, cultural_info)
SELECT fc.id, 450, 25.0, 45.0, 12.0, 
       'Nasi ayam consists of rice cooked in chicken broth, served with seasoned chicken, chili sauce, and cucumber.',
       'Nasi Ayam (Chicken Rice) is a popular dish in Malaysia, Singapore, and Indonesia, with roots in Hainanese cuisine.'
FROM food_categories fc
WHERE fc.name = 'nasi ayam'
AND NOT EXISTS (SELECT * FROM food_info WHERE food_category_id = fc.id);
