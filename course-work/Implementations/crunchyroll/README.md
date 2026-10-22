# Crunchyroll - база данни, Data Warehouse и Power BI анализ

| | |
|---|---|
| **Студент** | Йоан Павлов |
| **Факултетен номер** | 2501322043 |
| **Проект** | Crunchyroll - стрийминг платформа за аниме |

## Описание

Проектът моделира данните на **Crunchyroll** - онлайн платформа за гледане на аниме.
Обхванати са потребителите и техните абонаменти (Free, Fan, Mega Fan, Ultimate Fan) и плащания,
каталогът (студиа, сериали, сезони, епизоди, жанрове, езици за субтитри и дублаж) и
активността на потребителите (история на гледане, оценки и ревюта, списък „за гледане“).

## Инсталация и стартиране

**Изисквания:** Microsoft SQL Server 2019+, SQL Server Management Studio (SSMS), Power BI Desktop; по желание draw.io (diagrams.net).

1. Отворете SSMS и се свържете към SQL Server инстанцията.
2. Изпълнете скриптовете от sql папката **в този ред**:  `01_create_database.sql` -> `02_functions.sql` -> `03_stored_procedures.sql` -> `04_triggers.sql` ->  `05_seed_data.sql`.
3. Диаграмите се отварят в draw.io: **File -> Open from -> Device** -> файл `.drawio`.
4. Чрез PowerBI Desktop може да се отвори и .pbix файла, намиращ се в powerbi папката.