Алгоритм запуска:
1. Клонировать репозиторий на локальную машину (git clone https://github.com/ncuho/BDSnowflake.git)
2. Перейти в каталог с клоном
3. Выполнить (docker-compose up -d). Запустится Postgres и выполнятся все скрипты из init
4. Креды для подключения:
    Host: localhost
    Port: 5432
    Database: petstore
    User: postgres
    Password: postgres
5. Подключиться к готовой базе и проверить таблички можно либо через графические интерфейсы вроде DBeaver, либо через переход в контейнер через docker exec и запуск psql (docker exec -it bigdata_snowflake_db psql -U postgres -d petstore)