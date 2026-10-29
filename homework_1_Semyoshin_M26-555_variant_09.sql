/*
Домашнее задание к первому модулю
Дисциплина: «Базы данных и язык SQL»
ФИО студента: Семёшин Владислав Дмитриевич
Группа: М26-555
Вариант: 9
СУБД: PostgreSQL 14 и выше

УСЛОВИЕ ЗАДАНИЯ

Описание хранящихся в библиотеке книг. Включает в себя: библиотечные залы,
стеллажи, книги. Библиотечный зал описывается кратким и полным названием.
Стеллаж описывается: индексом и привязкой к залу. Книга описывается названием,
списком авторов, указанием тома или части (если есть), индексом ISBN, годом
издания, указанием индексов стеллажей и номеров полок на них, количеством
экземпляров.

Если две книги отличаются годом издания, томом или частью, то индекс ISBN
у них разный. Данные книги во всех заданиях необходимо считать разными.

ПРИНЯТАЯ МОДЕЛЬ

1. library_halls — библиотечные залы.
2. racks — стеллажи. Индекс стеллажа считаем уникальным во всей библиотеке.
3. shelves — полки. Номер полки уникален только в пределах своего стеллажа.
4. authors — авторы. Полное имя хранится одной строкой; однофамильцы
   и полные тёзки могут быть разными авторами.
5. books — отдельные издания книг. ISBN уникален и хранится без пробелов
   и дефисов. Допускаются форматы ISBN-10 и ISBN-13.
6. book_authors — связь книг с авторами «многие ко многим».
7. book_locations — размещение экземпляров книги на конкретной полке.

Связи: зал 1:M стеллаж; стеллаж 1:M полка; книга M:M автор;
книга M:M полка, у последней связи есть атрибут количества экземпляров.

Год издания, том и часть относятся к записи books. Поэтому нельзя создать
две разные записи с одним ISBN, в том числе с разными годами, томами
или частями. Экземпляры одного издания хранятся через book_locations.
Общее количество экземпляров книги равно сумме quantity по её размещениям.
Если размещений нет, количество экземпляров равно нулю. Отдельный итог
в books не хранится, чтобы он не расходился с количеством на полках.

ЗАПУСК

Открыть Query Tool в PgAdmin4 для пустой учебной базы PostgreSQL и выполнить
этот файл целиком. Скрипт создаёт все таблицы и связи в текущей схеме.
Предварительное заполнение справочников и установка расширений не нужны.
*/

BEGIN;

-- Библиотечные залы.
CREATE TABLE library_halls
(
    id serial PRIMARY KEY,
    short_name varchar(64) NOT NULL UNIQUE
        CHECK (btrim(short_name) <> ''),
    full_name varchar(256) NOT NULL
        CHECK (btrim(full_name) <> '')
);

-- Стеллаж относится ровно к одному залу.
CREATE TABLE racks
(
    id serial PRIMARY KEY,
    rack_index varchar(32) NOT NULL UNIQUE
        CHECK (btrim(rack_index) <> ''),
    hall_id integer NOT NULL REFERENCES library_halls(id)
);

-- Полка идентифицируется парой «стеллаж + номер полки».
CREATE TABLE shelves
(
    rack_id integer NOT NULL REFERENCES racks(id),
    shelf_number integer NOT NULL CHECK (shelf_number > 0),
    PRIMARY KEY (rack_id, shelf_number)
);

-- Авторы вынесены в отдельную таблицу, поскольку у книги их может быть несколько.
CREATE TABLE authors
(
    id serial PRIMARY KEY,
    full_name varchar(256) NOT NULL
        CHECK (btrim(full_name) <> '')
);

-- Каждое издание с собственным ISBN считается отдельной книгой.
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

-- Одна книга может иметь нескольких авторов, один автор — несколько книг.
CREATE TABLE book_authors
(
    book_id integer NOT NULL REFERENCES books(id),
    author_id integer NOT NULL REFERENCES authors(id),
    PRIMARY KEY (book_id, author_id)
);

-- На одной полке можно хранить несколько книг и несколько экземпляров каждой.
-- Книга может одновременно находиться на разных полках и стеллажах.
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

COMMIT;
