-- Run this SQL in your phpMyAdmin (attendance_db database)

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL, -- Assuming the PHP backend checks this
    unit_name VARCHAR(100),
    department_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert a test user
-- Password is '123456' hashed with BCrypt (which is standard for PHP's password_verify)
-- If your PHP backend uses plain text (not recommended), change this to just '123456'
INSERT INTO users (full_name, email, password, unit_name, department_name) 
VALUES 
('Test User', 'user@email.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Marketing', 'Sales');
