drop table if exists #__lrgallery_userfolders;
drop table if exists #__lrgallery_metadata;
drop table if exists #__lrgallery_meta;
drop table if exists #__lrgallery_photos;

create table #__lrgallery_photos
(
    id          int(11) not null AUTO_INCREMENT,
    name        varchar(200),
    user_id     int(11) not null,
    file_name   varchar(100) not null,
        primary key (id),
        foreign key (user_id) references #__users(id)
) ENGINE=MyISAM AUTO_INCREMENT=0 DEFAULT CHARSET=utf8;

create table #__lrgallery_meta
(
    id          int(11) not null AUTO_INCREMENT,
    name        varchar(100) not null,
    `desc`        varchar(100),
        primary key (id)
) ENGINE=MyISAM AUTO_INCREMENT=0 DEFAULT CHARSET=utf8;

create table #__lrgallery_metadata
(
    photo_id    int(11) not null,
    meta_id     int(11) not null,
    value       varchar(4000),
        primary key (photo_id, meta_id),
        foreign key (photo_id) references #__lrgallery_photos (id),
        foreign key (meta_id) references #__lrgallery_meta (id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

create table #__lrgallery_userfolders
(
    id          int(11) not null AUTO_INCREMENT,
    user_id     int(11) not null,
    folder_name varchar(100) not null unique,
        primary key (id),
        foreign key (user_id) references #__users(id)
) ENGINE=MyISAM AUTO_INCREMENT=0 DEFAULT CHARSET=utf8;
