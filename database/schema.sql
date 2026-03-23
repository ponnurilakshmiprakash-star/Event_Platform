-- Event Platform Database Schema
-- Optimized for MySQL

CREATE DATABASE IF NOT EXISTS event_platform;
USE event_platform;

-- 1. Users Table
-- Stores user account info for admin, organizers, and attendees
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  role ENUM('admin', 'organizer', 'attendee') DEFAULT 'attendee',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 2. Events Table
-- Stores core event information
CREATE TABLE events (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  -- Expanded categories to match frontend requirements
  category ENUM('technical', 'non-technical', 'hackathon', 'codethon', 'sports', 'dancing', 'music', 'arts', 'summit') DEFAULT 'technical',
  venue VARCHAR(200) NOT NULL,
  event_date DATE NOT NULL,
  event_time TIME NOT NULL,
  status ENUM('draft', 'published', 'completed', 'cancelled') DEFAULT 'draft',
  image_url VARCHAR(255),
  created_by INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

-- 3. Ticket Types Table
-- Defines different price points for an event (e.g. Student, VIP)
CREATE TABLE ticket_types (
  id INT AUTO_INCREMENT PRIMARY KEY,
  event_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  quantity INT NOT NULL DEFAULT 0,
  sold INT DEFAULT 0,
  FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
);

-- 4. Orders Table
-- Tracks purchases and payment status
CREATE TABLE orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  event_id INT NOT NULL,
  candidate_name VARCHAR(100) NOT NULL, -- Matches checkout "Full Name"
  college_name VARCHAR(200),             -- Matches checkout "College/Org"
  phone_number VARCHAR(20),               -- Added for communication
  total_amount DECIMAL(10,2) NOT NULL,
  payment_status ENUM('pending', 'paid', 'failed') DEFAULT 'pending',
  transaction_id VARCHAR(100),            -- Useful for UPI/Card reference
  order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
);

-- 5. Tickets Table
-- The actual digital ticket instances generated after an order
CREATE TABLE tickets (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  ticket_type_id INT NOT NULL,
  ticket_code VARCHAR(100) NOT NULL UNIQUE,
  checkin_status ENUM('not_checked', 'checked') DEFAULT 'not_checked',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (ticket_type_id) REFERENCES ticket_types(id) ON DELETE CASCADE
);

-- SEED DATA
-- Default Admin Account (Password: Admin@123)
-- bcrypt hash: $2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi
INSERT INTO users (full_name, email, password, role)
VALUES ('Super Admin', 'admin@event.com', 
'$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin')
ON DUPLICATE KEY UPDATE full_name = VALUES(full_name);
