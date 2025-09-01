CREATE DATABASE IF NOT EXISTS library_db CHARACTER SET utf8mb4;
USE library_db;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
CREATE TABLE branches (
  branch_id       INT AUTO_INCREMENT PRIMARY KEY,
  name            VARCHAR(100) NOT NULL,
  phone           VARCHAR(20),
  email           VARCHAR(120),
  address_line1   VARCHAR(150),
  address_line2   VARCHAR(150),
  city            VARCHAR(80),
  state_province  VARCHAR(80),
  postal_code     VARCHAR(20),
  country         VARCHAR(80),
  UNIQUE KEY uq_branches_name_city (name, city)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE staff (
  staff_id    INT AUTO_INCREMENT PRIMARY KEY,
  branch_id   INT NOT NULL,
  first_name  VARCHAR(60) NOT NULL,
  last_name   VARCHAR(60) NOT NULL,
  email       VARCHAR(120) NOT NULL,
  phone       VARCHAR(20),
  role        ENUM('Librarian','Assistant','Manager','Clerk','Other') NOT NULL DEFAULT 'Librarian',
  active      TINYINT(1) NOT NULL DEFAULT 1,
  hired_at    DATE,
  UNIQUE KEY uq_staff_email (email),
  KEY fk_staff_branch (branch_id),
  CONSTRAINT fk_staff_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE members (
  member_id   INT AUTO_INCREMENT PRIMARY KEY,
  branch_id   INT NOT NULL,
  first_name  VARCHAR(60) NOT NULL,
  last_name   VARCHAR(60) NOT NULL,
  email       VARCHAR(120) NOT NULL,
  phone       VARCHAR(20),
  joined_at   DATE NOT NULL,
  status      ENUM('Active','Suspended','Closed') NOT NULL DEFAULT 'Active',
  UNIQUE KEY uq_members_email (email),
  KEY fk_members_branch (branch_id),
  CONSTRAINT fk_members_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE member_addresses (
  member_id      INT PRIMARY KEY,
  address_line1  VARCHAR(150) NOT NULL,
  address_line2  VARCHAR(150),
  city           VARCHAR(80) NOT NULL,
  state_province VARCHAR(80),
  postal_code    VARCHAR(20),
  country        VARCHAR(80) NOT NULL,
  CONSTRAINT fk_member_addresses_member FOREIGN KEY (member_id) REFERENCES members(member_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE publishers (
  publisher_id INT AUTO_INCREMENT PRIMARY KEY,
  name         VARCHAR(150) NOT NULL,
  website      VARCHAR(200),
  UNIQUE KEY uq_publishers_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE authors (
  author_id  INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(60) NOT NULL,
  last_name  VARCHAR(60) NOT NULL,
  full_name  VARCHAR(150) GENERATED ALWAYS AS (CONCAT(first_name,' ',last_name)) STORED,
  UNIQUE KEY uq_authors_name (first_name, last_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(80) NOT NULL,
  UNIQUE KEY uq_categories_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE books (
  book_id          INT AUTO_INCREMENT PRIMARY KEY,
  title            VARCHAR(200) NOT NULL,
  isbn13           CHAR(13),
  publisher_id     INT,
  publication_year YEAR,
  language_code    VARCHAR(10),
  pages            INT,
  UNIQUE KEY uq_books_isbn13 (isbn13),
  KEY fk_books_publisher (publisher_id),
  CONSTRAINT fk_books_publisher FOREIGN KEY (publisher_id) REFERENCES publishers(publisher_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE book_authors (
  book_id   INT NOT NULL,
  author_id INT NOT NULL,
  author_order TINYINT UNSIGNED DEFAULT 1,
  PRIMARY KEY (book_id, author_id),
  KEY fk_ba_author (author_id),
  CONSTRAINT fk_ba_book   FOREIGN KEY (book_id)   REFERENCES books(book_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_ba_author FOREIGN KEY (author_id) REFERENCES authors(author_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE book_categories (
  book_id     INT NOT NULL,
  category_id INT NOT NULL,
  PRIMARY KEY (book_id, category_id),
  KEY fk_bc_category (category_id),
  CONSTRAINT fk_bc_book     FOREIGN KEY (book_id)     REFERENCES books(book_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_bc_category FOREIGN KEY (category_id) REFERENCES categories(category_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE book_copies (
  copy_id     INT AUTO_INCREMENT PRIMARY KEY,
  book_id     INT NOT NULL,
  branch_id   INT NOT NULL,
  barcode     VARCHAR(50) NOT NULL,
  status      ENUM('Available','OnLoan','Reserved','Lost','Repair') NOT NULL DEFAULT 'Available',
  acquired_on DATE,
  KEY fk_copies_book   (book_id),
  KEY fk_copies_branch (branch_id),
  UNIQUE KEY uq_copies_barcode (barcode),
  CONSTRAINT fk_copies_book   FOREIGN KEY (book_id)   REFERENCES books(book_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_copies_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE loans (
  loan_id           INT AUTO_INCREMENT PRIMARY KEY,
  copy_id           INT NOT NULL,
  member_id         INT NOT NULL,
  checkout_staff_id INT,
  returned_staff_id INT,
  checkout_date     DATETIME NOT NULL,
  due_date          DATETIME NOT NULL,
  return_date       DATETIME,
  status            ENUM('CheckedOut','Returned','Overdue','Lost') NOT NULL DEFAULT 'CheckedOut',
  KEY fk_loans_copy      (copy_id),
  KEY fk_loans_member    (member_id),
  KEY fk_loans_checkout  (checkout_staff_id),
  KEY fk_loans_returned  (returned_staff_id),
  CONSTRAINT fk_loans_copy      FOREIGN KEY (copy_id)           REFERENCES book_copies(copy_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_loans_member    FOREIGN KEY (member_id)         REFERENCES members(member_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_loans_checkout  FOREIGN KEY (checkout_staff_id) REFERENCES staff(staff_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_loans_returned  FOREIGN KEY (returned_staff_id) REFERENCES staff(staff_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE reservations (
  reservation_id  INT AUTO_INCREMENT PRIMARY KEY,
  member_id       INT NOT NULL,
  book_id         INT NOT NULL,
  requested_at    DATETIME NOT NULL,
  status          ENUM('Active','Fulfilled','Cancelled','Expired') NOT NULL DEFAULT 'Active',
  fulfilled_copy_id INT,
  KEY fk_res_member (member_id),
  KEY fk_res_book   (book_id),
  KEY fk_res_copy   (fulfilled_copy_id),
  CONSTRAINT fk_res_member FOREIGN KEY (member_id) REFERENCES members(member_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_res_book   FOREIGN KEY (book_id)   REFERENCES books(book_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_res_copy   FOREIGN KEY (fulfilled_copy_id) REFERENCES book_copies(copy_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  UNIQUE KEY uq_active_reservation (member_id, book_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE fines (
  fine_id    INT AUTO_INCREMENT PRIMARY KEY,
  loan_id    INT NOT NULL,
  amount     DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
  reason     ENUM('Overdue','Lost','Damage','Other') NOT NULL,
  assessed_at DATETIME NOT NULL,
  KEY fk_fines_loan (loan_id),
  CONSTRAINT fk_fines_loan FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE fine_payments (
  payment_id  INT AUTO_INCREMENT PRIMARY KEY,
  fine_id     INT NOT NULL,
  staff_id    INT,
  amount      DECIMAL(10,2) NOT NULL CHECK (amount > 0),
  paid_at     DATETIME NOT NULL,
  method      ENUM('Cash','Card','MobileMoney','Other') NOT NULL,
  KEY fk_fp_fine  (fine_id),
  KEY fk_fp_staff (staff_id),
  CONSTRAINT fk_fp_fine  FOREIGN KEY (fine_id)  REFERENCES fines(fine_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_fp_staff FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
SET FOREIGN_KEY_CHECKS = 1;