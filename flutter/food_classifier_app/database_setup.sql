-- Food Classification App Database Setup

-- Create the database
CREATE DATABASE IF NOT EXISTS food_classifier_db;
USE food_classifier_db;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  email VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(100),
  weight FLOAT,
  height FLOAT,
  gender ENUM('male', 'female', 'other'),
  activity_level ENUM('sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extremely_active'),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create food_categories table
CREATE TABLE IF NOT EXISTS food_categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create food_predictions table
CREATE TABLE IF NOT EXISTS food_predictions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  food_category_id INT NOT NULL,
  confidence FLOAT NOT NULL,
  image_path VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (food_category_id) REFERENCES food_categories(id) ON DELETE CASCADE
);

-- Create food_info table
CREATE TABLE IF NOT EXISTS food_info (
  id INT AUTO_INCREMENT PRIMARY KEY,
  food_category_id INT NOT NULL,
  calories INT,
  protein FLOAT,
  carbs FLOAT,
  fats FLOAT,
  description TEXT,
  cultural_info TEXT,
  FOREIGN KEY (food_category_id) REFERENCES food_categories(id) ON DELETE CASCADE
);

-- Create ingredients table
CREATE TABLE IF NOT EXISTS ingredients (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create prediction_ingredients table for storing ingredient predictions
CREATE TABLE IF NOT EXISTS prediction_ingredients (
  id INT AUTO_INCREMENT PRIMARY KEY,
  prediction_id INT NOT NULL,
  ingredient_id INT NOT NULL,
  confidence FLOAT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (prediction_id) REFERENCES food_predictions(id) ON DELETE CASCADE,
  FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE
);

-- Insert default food categories that match the model
INSERT INTO food_categories (name, description) VALUES
('cendol', 'A traditional Southeast Asian dessert made with green rice flour jelly, coconut milk, and palm sugar syrup'),
('ketupat', 'A compressed rice cake wrapped in woven palm leaf pouches'),
('laksa', 'A spicy noodle soup popular in Southeast Asian cuisine'),
('nasi lemak', 'A fragrant rice dish cooked in coconut milk and pandan leaf');

-- Insert sample food info for each category
INSERT INTO food_info (food_category_id, calories, protein, carbs, fats, description, cultural_info) VALUES
(1, 150, 0.5, 30.0, 3.0, 'Cendol is a sweet dessert containing green rice flour jelly, coconut milk and palm sugar syrup.', 'Popular in Indonesia, Malaysia, Singapore, and parts of Thailand.'),
(2, 180, 3.5, 40.0, 0.3, 'Ketupat is a compressed rice cake wrapped in woven palm leaf pouches.', 'Traditional food often served during festive occasions like Eid al-Fitr.'),
(3, 450, 15.0, 60.0, 15.0, 'Laksa is a spicy noodle soup combining Chinese and Malay culinary traditions.', 'Various regional variants exist throughout Southeast Asia.'),
(4, 400, 10.0, 50.0, 15.0, 'Nasi lemak is rice cooked in coconut milk, served with sambal, fried anchovies, peanuts and cucumber.', 'Often referred to as the national dish of Malaysia.');

-- Insert common ingredients for Malaysian dishes
INSERT INTO ingredients (name, description) VALUES
('Ikan Bilis', 'Small dried anchovies commonly used in Malaysian cuisine'),
('Telur', 'Boiled or fried egg, often served as a side dish'),
('Sambal', 'Spicy chili paste made with various ingredients'),
('Timun', 'Fresh cucumber slices'),
('Kacang', 'Roasted peanuts'),
('Pandan', 'Aromatic leaves used in cooking'),
('Santan', 'Coconut milk'),
('Nasi', 'Steamed rice');

-- Drop the old prediction_side_dishes table since we're replacing it
DROP TABLE IF EXISTS prediction_side_dishes;

-- Create a user for the application to connect to the database
CREATE USER IF NOT EXISTS 'food_app_user'@'localhost' IDENTIFIED BY 'food_app_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON food_classifier_db.* TO 'food_app_user'@'localhost';
FLUSH PRIVILEGES;