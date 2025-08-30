-- إنشاء قاعدة البيانات لـ BizChat
CREATE DATABASE IF NOT EXISTS bizchat CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bizchat;

-- جدول المستخدمين
CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    location VARCHAR(255) NOT NULL,
    avatar VARCHAR(500),
    is_verified BOOLEAN DEFAULT FALSE,
    is_online BOOLEAN DEFAULT FALSE,
    last_seen TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- جدول رموز OTP
CREATE TABLE otp_codes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    code VARCHAR(6) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    INDEX idx_phone_code (phone_number, code),
    INDEX idx_expires (expires_at)
);

-- جدول الجلسات
CREATE TABLE sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    token VARCHAR(64) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_token (token),
    INDEX idx_expires (expires_at)
);

-- جدول المحادثات
CREATE TABLE chats (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255),
    is_group BOOLEAN DEFAULT FALSE,
    participants JSON NOT NULL,
    created_by VARCHAR(36),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

-- جدول الرسائل
CREATE TABLE messages (
    id VARCHAR(36) PRIMARY KEY,
    chat_id VARCHAR(36) NOT NULL,
    sender_id VARCHAR(36) NOT NULL,
    content TEXT,
    message_type ENUM('text', 'image', 'video', 'audio', 'file', 'sticker', 'location') DEFAULT 'text',
    image_url VARCHAR(500),
    audio_url VARCHAR(500),
    sticker_url VARCHAR(500),
    sticker_id VARCHAR(36),
    location_lat DECIMAL(10, 8),
    location_lon DECIMAL(11, 8),
    location_name VARCHAR(255),
    reply_to_message_id VARCHAR(36),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN DEFAULT FALSE,
    is_delivered BOOLEAN DEFAULT FALSE,
    is_edited BOOLEAN DEFAULT FALSE,
    edited_at TIMESTAMP NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (reply_to_message_id) REFERENCES messages(id) ON DELETE SET NULL,
    INDEX idx_chat_timestamp (chat_id, timestamp),
    INDEX idx_sender (sender_id)
);

-- جدول الحالات
CREATE TABLE stories (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    location VARCHAR(255) NOT NULL,
    content TEXT,
    image_url VARCHAR(500),
    video_url VARCHAR(500),
    background_color VARCHAR(7) DEFAULT '#075e54',
    text_color VARCHAR(7) DEFAULT '#ffffff',
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    view_count INT DEFAULT 0,
    viewers JSON DEFAULT ('[]'),
    category VARCHAR(50) DEFAULT 'general',
    is_highlight BOOLEAN DEFAULT FALSE,
    privacy_settings JSON DEFAULT ('{"isPublic": true}'),
    poll_options JSON,
    music_url VARCHAR(500),
    link_url VARCHAR(500),
    link_title VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_location_expires (location, expires_at),
    INDEX idx_user_timestamp (user_id, timestamp)
);

-- جدول ميزات التطبيق
CREATE TABLE app_features (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_enabled BOOLEAN DEFAULT TRUE,
    category VARCHAR(100) DEFAULT 'general',
    priority INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- جدول جلسات الإدارة
CREATE TABLE admin_sessions (
    token VARCHAR(70) PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    INDEX idx_expires (expires_at)
);

-- جدول المتاجر (للمستقبل)
CREATE TABLE stores (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    owner_id VARCHAR(36) NOT NULL,
    category VARCHAR(100),
    location VARCHAR(255),
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(255),
    logo_url VARCHAR(500),
    cover_url VARCHAR(500),
    status ENUM('pending', 'approved', 'rejected', 'suspended') DEFAULT 'pending',
    rejection_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_owner (owner_id),
    INDEX idx_status (status),
    INDEX idx_location (location)
);

-- جدول الطلبات (للمستقبل)
CREATE TABLE orders (
    id VARCHAR(36) PRIMARY KEY,
    customer_id VARCHAR(36) NOT NULL,
    store_id VARCHAR(36),
    total_amount DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'confirmed', 'prepared', 'delivered', 'cancelled') DEFAULT 'pending',
    delivery_address TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE SET NULL,
    INDEX idx_customer (customer_id),
    INDEX idx_status (status),
    INDEX idx_created (created_at)
);

-- جدول طلبات التوثيق (للمستقبل)
CREATE TABLE verification_requests (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    request_type VARCHAR(50) NOT NULL,
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    reason TEXT,
    admin_note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_status (status)
);

-- إضافة حقول جديدة لجدول المستخدمين
ALTER TABLE users ADD COLUMN is_admin BOOLEAN DEFAULT FALSE;

-- إدراج الميزات الافتراضية
INSERT INTO app_features (id, name, description, is_enabled, category, priority) VALUES
('messaging', 'المراسلة', 'إرسال واستقبال الرسائل النصية والوسائط', true, 'communication', 1),
('stories', 'الحالات', 'مشاركة الحالات والصور المؤقتة', true, 'social', 2),
('stores', 'المتاجر', 'إنشاء وإدارة المتاجر الإلكترونية', true, 'commerce', 3),
('products', 'المنتجات', 'عرض وبيع المنتجات', true, 'commerce', 4),
('cart', 'سلة التسوق', 'إضافة المنتجات وإجراء عمليات الشراء', true, 'commerce', 5),
('admin', 'لوحة الإدارة', 'إدارة المستخدمين والمحتوى والإعدادات', true, 'management', 10);

-- إنشاء مستخدم تجريبي
INSERT INTO users (id, name, phone_number, location, is_verified, is_admin) VALUES 
('demo-user-1', 'أحمد محمد', '+213555123456', 'تندوف', true, false),
('admin-user-1', 'المدير العام', '+213123456789', 'الجزائر', true, true);