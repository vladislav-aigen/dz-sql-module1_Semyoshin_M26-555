/*
Домашнее задание № 2. Заполнение таблиц и выполнение SQL-запросов
Дисциплина: «Базы данных и язык SQL»
ФИО студента: Семёшин Владислав Дмитриевич
Группа: М26-555
Вариант: 9 — библиотека
СУБД: PostgreSQL 14 и выше

УСЛОВИЯ ЗАДАНИЯ

Заполните таблицы, созданные в рамках домашнего задания к практическому
занятию 1, не менее чем пятью осмысленными записями. Данные возьмите
из аналогичных систем в реальной жизни. Заполнение оформите в виде
SQL-запросов.

Вариант 9:
1. Выберите все книги (все поля таблицы), у которых контрольная цифра ISBN
   не более 5.
2. Выберите все книги, которые написаны более чем одним автором,
   а также количество данных авторов.

Работа сдаётся одним файлом с полностью выполняемым скриптом;
в начале файла должны быть указаны ФИО, вариант и условия задания.

ПОРЯДОК ЗАПУСКА

Открыть Query Tool в PgAdmin4 для учебной базы PostgreSQL и выполнить
файл целиком. Скрипт сам создаёт семь таблиц с той же структурой,
что в домашнем задании № 1, заполняет их и выполняет оба SELECT.
Предварительно запускать файл первого задания не требуется.

Для самостоятельного запуска используется новая схема homework_2_library.
Таблицы первого задания в public не изменяются. Схема homework_2_library
до запуска не должна существовать. Скрипт не удаляет имеющиеся данные.
CREATE SCHEMA создаёт раздел внутри выбранной базы; сама база выбирается
при открытии Query Tool. Нужны права на создание схем в этой базе.

Оба итоговых SELECT расположены после COMMIT и используют полные имена
таблиц, поэтому их можно повторно выполнять отдельно от создания таблиц.

ПРОИСХОЖДЕНИЕ ДАННЫХ

Названия книг, авторы, ISBN и годы публикации взяты из каталогов издателей.
В publication_year используется год публикации, а не отличающийся от него
год Copyright: например, для Clean Code это 2008, для первого издания
The Pragmatic Programmer — 1999, для второго — 2019.

Источники библиографических записей:
[1] The C Programming Language, 2nd edition — Pearson / InformIT:
https://www.informit.com/store/c-programming-language-9780131103627
[2] Clean Code — Pearson / InformIT:
https://www.informit.com/store/clean-code-a-handbook-of-agile-software-craftsmanship-9780132350884
[3] The Pragmatic Programmer, 1st edition — Addison-Wesley / InformIT:
https://www.informit.com/store/pragmatic-programmer-from-journeyman-to-master-9780201616224
[4] The Pragmatic Programmer, 2nd edition — Addison-Wesley / InformIT:
https://www.informit.com/store/pragmatic-programmer-your-journey-to-mastery-20th-anniversary-9780135957059
[5] Designing Data-Intensive Applications, 1st edition — O'Reilly:
https://www.oreilly.com/library/view/designing-data-intensive-applications/9781491903063/copyright-page01.html
[6] Introduction to Algorithms, 4th edition — MIT Press:
https://mitpress.mit.edu/9780262046305/introduction-to-algorithms/

Названия пяти залов взяты с официального сайта Российской государственной
библиотеки: Первый, Третий, Тихий, Дубовый, зал коворкинга и выставок.
https://www.rsl.ru/for_partners/ploshadki-rgb/chitalnye-zaly/

Индексы стеллажей, номера полок, размещения и количества экземпляров —
осмысленные учебные данные для модели библиотечного хранения. Они не
являются сведениями о фактическом наличии этих книг в залах РГБ.

Объём данных: 5 залов, 6 стеллажей, 12 полок, 10 авторов, 6 книг,
12 связей книг с авторами, 12 размещений книг. Во всех таблицах >= 5 строк.
Одна запись books соответствует отдельному изданию; ISBN-10 и ISBN-13
одного издания не создаются как две разные книги.
*/

BEGIN;

CREATE SCHEMA homework_2_library;
SET LOCAL search_path TO homework_2_library;

-- 1. Создание таблиц: структура сохранена из домашнего задания № 1.

CREATE TABLE library_halls
(
    id serial PRIMARY KEY,
    short_name varchar(64) NOT NULL UNIQUE
        CHECK (btrim(short_name) <> ''),
    full_name varchar(256) NOT NULL
        CHECK (btrim(full_name) <> '')
);

CREATE TABLE racks
(
    id serial PRIMARY KEY,
    rack_index varchar(32) NOT NULL UNIQUE
        CHECK (btrim(rack_index) <> ''),
    hall_id integer NOT NULL REFERENCES library_halls(id)
);

CREATE TABLE shelves
(
    rack_id integer NOT NULL REFERENCES racks(id),
    shelf_number integer NOT NULL CHECK (shelf_number > 0),
    PRIMARY KEY (rack_id, shelf_number)
);

CREATE TABLE authors
(
    id serial PRIMARY KEY,
    full_name varchar(256) NOT NULL
        CHECK (btrim(full_name) <> '')
);

CREATE TABLE books
(
    id serial PRIMARY KEY,
    title varchar(512) NOT NULL
        CHECK (btrim(title) <> ''),
    isbn varchar(13) NOT NULL UNIQUE
        CHECK (isbn ~ '^([0-9]{9}[0-9X]|[0-9]{13})$'),
    publication_year smallint NOT NULL
        CHECK (publication_year BETWEEN 1 AND 9999),
    volume varchar(64)
        CHECK (volume IS NULL OR btrim(volume) <> ''),
    part varchar(64)
        CHECK (part IS NULL OR btrim(part) <> '')
);

CREATE TABLE book_authors
(
    book_id integer NOT NULL REFERENCES books(id),
    author_id integer NOT NULL REFERENCES authors(id),
    PRIMARY KEY (book_id, author_id)
);

CREATE TABLE book_locations
(
    book_id integer NOT NULL REFERENCES books(id),
    rack_id integer NOT NULL,
    shelf_number integer NOT NULL,
    quantity integer NOT NULL DEFAULT 1 CHECK (quantity > 0),
    PRIMARY KEY (book_id, rack_id, shelf_number),
    FOREIGN KEY (rack_id, shelf_number)
        REFERENCES shelves(rack_id, shelf_number)
);

-- 2. Заполнение таблиц.
-- Таблицы создаются пустыми. SERIAL назначает id начиная с 1.
-- Значения id не вставляются вручную: последовательности остаются корректными.

INSERT INTO library_halls (short_name, full_name) VALUES
    ('Первый', 'Первый читальный зал'),
    ('Третий', 'Третий читальный зал'),
    ('Тихий', 'Тихий читальный зал'),
    ('Дубовый', 'Дубовый читальный зал'),
    ('Коворкинг', 'Зал коворкинга и выставок');

-- Учебные индексы: первые два стеллажа находятся в Первом зале.
INSERT INTO racks (rack_index, hall_id) VALUES
    ('P-01', 1),
    ('P-02', 1),
    ('T-01', 2),
    ('TH-01', 3),
    ('D-01', 4),
    ('K-01', 5);

-- У каждого стеллажа две полки; одинаковые номера в разных стеллажах допустимы.
INSERT INTO shelves (rack_id, shelf_number) VALUES
    (1, 1), (1, 2),
    (2, 1), (2, 2),
    (3, 1), (3, 2),
    (4, 1), (4, 2),
    (5, 1), (5, 2),
    (6, 1), (6, 2);

INSERT INTO authors (full_name) VALUES
    ('Brian W. Kernighan'),     -- id = 1
    ('Dennis M. Ritchie'),      -- id = 2
    ('Robert C. Martin'),       -- id = 3
    ('Andrew Hunt'),            -- id = 4
    ('David Thomas'),           -- id = 5
    ('Martin Kleppmann'),       -- id = 6
    ('Thomas H. Cormen'),       -- id = 7
    ('Charles E. Leiserson'),   -- id = 8
    ('Ronald L. Rivest'),       -- id = 9
    ('Clifford Stein');         -- id = 10

INSERT INTO books (title, isbn, publication_year, volume, part) VALUES
    -- id = 1; второе издание; источник [1]; контрольная цифра 7.
    ('The C Programming Language',
     '9780131103627', 1988, NULL, NULL),
    -- id = 2; источник [2]; контрольная цифра 4.
    ('Clean Code: A Handbook of Agile Software Craftsmanship',
     '9780132350884', 2008, NULL, NULL),
    -- id = 3; первое издание; источник [3]; ISBN-10 с контрольным символом X.
    ('The Pragmatic Programmer: From Journeyman to Master',
     '020161622X', 1999, NULL, NULL),
    -- id = 4; второе издание; источник [4]; контрольная цифра 9.
    ('The Pragmatic Programmer: Your Journey to Mastery, 20th Anniversary Edition',
     '9780135957059', 2019, NULL, NULL),
    -- id = 5; первое издание; источник [5]; контрольная цифра 0.
    ('Designing Data-Intensive Applications',
     '9781449373320', 2017, NULL, NULL),
    -- id = 6; четвёртое издание; источник [6]; контрольная цифра 5.
    ('Introduction to Algorithms',
     '9780262046305', 2022, NULL, NULL);

INSERT INTO book_authors (book_id, author_id) VALUES
    (1, 1), (1, 2),                    -- Kernighan, Ritchie
    (2, 3),                            -- Martin
    (3, 4), (3, 5),                    -- Hunt, Thomas
    (4, 4), (4, 5),                    -- Hunt, Thomas
    (5, 6),                            -- Kleppmann
    (6, 7), (6, 8), (6, 9), (6, 10);   -- Cormen, Leiserson, Rivest, Stein

-- Учебные размещения. Книги 1, 2, 3, 4, 5, 6 встречаются на нескольких полках.
-- На полке (стеллаж 1, полка 1) находятся две разные книги.
INSERT INTO book_locations (book_id, rack_id, shelf_number, quantity) VALUES
    (1, 1, 1, 3),
    (2, 1, 1, 2),
    (3, 1, 2, 2),
    (4, 2, 1, 4),
    (5, 2, 2, 3),
    (6, 3, 1, 2),
    (1, 3, 2, 1),
    (2, 4, 1, 2),
    (3, 4, 2, 1),
    (4, 5, 1, 2),
    (5, 5, 2, 1),
    (6, 6, 1, 1);

COMMIT;

-- 3. Задание 1.
-- Все поля книг, у которых контрольная цифра ISBN не более 5.
-- Контрольный символ — последний символ ISBN. Сравнение с перечнем цифр
-- не требует преобразования строки в число и корректно исключает X
-- в ISBN-10 (X означает контрольное значение 10).
-- Ожидаются 3 строки: книги с id 2, 5, 6 (окончания ISBN: 4, 0, 5).

SELECT b.*
FROM homework_2_library.books AS b
WHERE RIGHT(b.isbn, 1) IN ('0', '1', '2', '3', '4', '5')
ORDER BY b.id;

-- 4. Задание 2.
-- Книги, написанные более чем одним автором, и количество их авторов.
-- Каждая пара book_id + author_id уникальна благодаря первичному ключу.
-- Размещения книг не присоединяются: число копий не влияет на число авторов.
-- Ожидаются 4 строки: id 6 — 4 автора; id 1, 3, 4 — по 2 автора.

SELECT
    b.id,
    b.title,
    b.isbn,
    b.publication_year,
    b.volume,
    b.part,
    COUNT(ba.author_id) AS author_count
FROM homework_2_library.books AS b
JOIN homework_2_library.book_authors AS ba ON ba.book_id = b.id
GROUP BY b.id, b.title, b.isbn, b.publication_year, b.volume, b.part
HAVING COUNT(ba.author_id) > 1
ORDER BY author_count DESC, b.id;
