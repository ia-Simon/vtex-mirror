create extension if not exists "uuid-ossp";

create table migration (
  id                  serial,
  exec_date           timestamp default current_timestamp,
  name                varchar(50) not null unique,

  primary key (id)
);