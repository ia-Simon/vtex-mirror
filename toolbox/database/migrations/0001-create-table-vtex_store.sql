do $$
declare
    selected_migration migration%rowtype;
    migration_name migration.name%type := '0001-create-table-vtex_store.sql';
begin
    select * from migration
    into selected_migration
    where name=migration_name;

    if not found then 
        -- MIGRATION BLOCK (write the operations here)

        create table vtex_store (
            id                  uuid default uuid_generate_v4(),
            name                varchar(128) not null unique,
            store_key           varchar(128) not null unique,
            vtex_app_key        varchar(128) not null,
            vtex_app_token      varchar(128) not null,

            primary key (id)
        );

        -- END MIGRATION BLOCK
        insert into migration (name) values (migration_name);
    end if;
end $$